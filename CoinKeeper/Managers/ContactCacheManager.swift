//
//  ContactCacheManager.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import Contacts
import PhoneNumberKit

protocol ContactCacheManagerType: AnyObject {

  var viewContext: NSManagedObjectContext { get }
  func createBackgroundContext() -> NSManagedObjectContext
  func createRootBackgroundContext() -> NSManagedObjectContext

  func createPhoneNumberFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber>
  func predicate(forSearch searchText: String) -> NSPredicate

  func phoneNumberCount(in context: NSManagedObjectContext) throws -> Int
  func allValidatedMetadata(in context: NSManagedObjectContext) throws -> [CCMValidatedMetadata]
  func allCachedContacts(in context: NSManagedObjectContext) throws -> [CCMContact]

  func deleteSystemContactData(in context: NSManagedObjectContext) throws
  func persistContacts(_ contacts: [CNContact],
                       inputs: CachedPhoneNumberDependencies,
                       progress: ContactProgressHandler?,
                       in context: NSManagedObjectContext) throws

  func validatedMetadata(for globalPhoneNumber: GlobalPhoneNumber, in context: NSManagedObjectContext) -> CCMValidatedMetadata?
  func managedContactComponents(forGlobalPhoneNumber number: GlobalPhoneNumber) -> ManagedContactComponents?

}

class ContactCacheManager: ContactCacheManagerType {

  private let stackConfig: CoreDataStackConfig
  private let container: NSPersistentContainer

  private lazy var rootContext: NSManagedObjectContext = {
    let context = self.container.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.name = "RootContext_Contacts"
    return context
  }()

  lazy var viewContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.parent = rootContext
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.name = "ViewContext_Contacts"
    return context
  }()

  func createBackgroundContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.parent = viewContext
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.name = "BackgroundContext_Contacts_\(Date().timeIntervalSince1970)"
    return context
  }

  func createRootBackgroundContext() -> NSManagedObjectContext {
    let context = self.container.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.name = "TemporaryRootContext_Contacts_\(Date().timeIntervalSince1970)"
    return context
  }

  convenience init() {
    let config = CoreDataStackConfig(stackType: .contactCache, storeType: .disk)
    self.init(stackConfig: config)
  }

  init(stackConfig: CoreDataStackConfig) {
    self.stackConfig = stackConfig
    self.container = stackConfig.stack.persistentContainer
  }

  func createPhoneNumberFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber> {
    let fetchRequest: NSFetchRequest<CCMPhoneNumber> = CCMPhoneNumber.fetchRequest()
    fetchRequest.predicate = standardFetchedResultsControllerPredicate()
    fetchRequest.sortDescriptors = frcSortDescriptors()
    fetchRequest.fetchBatchSize = 25

    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: viewContext,
                                                sectionNameKeyPath: #keyPath(CCMPhoneNumber.verificationStatus),
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    return controller
  }

  func validatedMetadata(for globalPhoneNumber: GlobalPhoneNumber, in context: NSManagedObjectContext) -> CCMValidatedMetadata? {
    return CCMValidatedMetadata.find(withNumber: globalPhoneNumber, in: context)
  }

  func managedContactComponents(forGlobalPhoneNumber number: GlobalPhoneNumber) -> ManagedContactComponents? {
    var components: ManagedContactComponents?
    viewContext.performAndWait {
      if let foundMetadata = validatedMetadata(for: number, in: viewContext),
        let displayName = foundMetadata.firstDisplayNameForCachedPhoneNumbers(),
        let phoneInputs = ManagedPhoneNumberInputs(countryCode: foundMetadata.countryCode, nationalNumber: foundMetadata.nationalNumber) {
        let counterpartyInputs = ManagedCounterpartyInputs(name: displayName)
        components = ManagedContactComponents(counterpartyInputs: counterpartyInputs, phonenumberInputs: phoneInputs)
      }
    }
    return components
  }

  /// Use this to update the fetched results controller as the user searches
  func predicate(forSearch searchText: String) -> NSPredicate {
    var andPredicates = [standardFetchedResultsControllerPredicate()]

    if searchText.isNotEmpty {
      let displayPath = #keyPath(CCMPhoneNumber.cachedContact.displayName)
      let givenPath = #keyPath(CCMPhoneNumber.cachedContact.givenName)
      let familyPath = #keyPath(CCMPhoneNumber.cachedContact.familyName)

      let displayPredicate = NSPredicate(format: "\(displayPath) BEGINSWITH[cd] %@", searchText)
      let givenPredicate = NSPredicate(format: "\(givenPath) BEGINSWITH[cd] %@", searchText)
      let familyPredicate = NSPredicate(format: "\(familyPath) BEGINSWITH[cd] %@", searchText)

      let searchPredicate = NSCompoundPredicate(type: .or, subpredicates: [displayPredicate,
                                                                           givenPredicate,
                                                                           familyPredicate])
      andPredicates.append(searchPredicate)
    }

    return NSCompoundPredicate(type: .and, subpredicates: andPredicates)
  }

  private func standardFetchedResultsControllerPredicate() -> NSPredicate {
    // Likely the case for companies/organizations
    let noNamePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      NSPredicate(format: "\(#keyPath(CCMPhoneNumber.cachedContact.familyName)) == nil"),
      NSPredicate(format: "\(#keyPath(CCMPhoneNumber.cachedContact.givenName)) == nil")
      ]
    )
    let hasNamePredicate = NSCompoundPredicate(notPredicateWithSubpredicate: noNamePredicate)
    let notSpamPredicate = NSPredicate(format: "\(#keyPath(CCMPhoneNumber.cachedContact.displayName)) != %@", "SPAM")
    let andPredicates = [hasNamePredicate, notSpamPredicate]
    return NSCompoundPredicate(type: .and, subpredicates: andPredicates)
  }

  private func frcSortDescriptors() -> [NSSortDescriptor] {
    return [
      NSSortDescriptor(key: #keyPath(CCMPhoneNumber.verificationStatus), ascending: true), //must be ascending and match sectionNameKeyPath
      NSSortDescriptor(key: #keyPath(CCMPhoneNumber.cachedContact.familyName), ascending: true),
      NSSortDescriptor(key: #keyPath(CCMPhoneNumber.cachedContact.givenName), ascending: true),
      NSSortDescriptor(key: #keyPath(CCMPhoneNumber.sanitizedOriginalNumber), ascending: true)
    ]
  }

  func allValidatedMetadata(in context: NSManagedObjectContext) throws -> [CCMValidatedMetadata] {
    let request: NSFetchRequest<CCMValidatedMetadata> = CCMValidatedMetadata.fetchRequest()
    return try context.fetch(request)
  }

  func allCachedContacts(in context: NSManagedObjectContext) throws -> [CCMContact] {
    let request: NSFetchRequest<CCMContact> = CCMContact.fetchRequest()
    return try context.fetch(request)
  }

  func persistContacts(_ contacts: [CNContact],
                       inputs: CachedPhoneNumberDependencies,
                       progress: ContactProgressHandler?,
                       in context: NSManagedObjectContext) throws {

    let regionCode = Locale.current.regionCode?.uppercased() ?? "US"

    let totalContactCount = contacts.count
    let batchSize = (totalContactCount > 1000) ? 300 : 150
    let contactBatches = contacts.chunked(by: batchSize)

    for (i, batch) in contactBatches.enumerated() {
      for contact in batch {
        let labeledNumbers = contact.phoneNumbers
        guard labeledNumbers.isNotEmpty else { continue }

        guard let cachedContact = CCMContact(cnContact: contact,
                                             formatter: inputs.formatter,
                                             insertInto: context) else { continue }

        for labeledNumber in labeledNumbers {
          let originalPhoneNumber = labeledNumber.value.stringValue
          let sanitizedOriginal = originalPhoneNumber.removingNonDecimalCharacters()
          let sanitizedForParsing = originalPhoneNumber.removingNonDecimalCharacters(keepingCharactersIn: "+")

          do {
            let parsedNumber = try phoneNumberKit.parse(sanitizedForParsing, withRegion: regionCode, ignoreType: false)
            // CCMPhoneNumber objects don't use findOrCreate, because there may be duplicate contacts
            // and we don't want to delete all instances of a phone number if the duplicate is removed
            let cachedPhoneNumber = self.createCachedPhoneNumber(for: parsedNumber,
                                                                 sanitizedOriginal: sanitizedOriginal,
                                                                 labelKey: labeledNumber.label,
                                                                 dependencies: inputs,
                                                                 in: context)
            cachedPhoneNumber.cachedContact = cachedContact

          } catch {
            // not parseable, will not create or link CCMValidatedMetadata
            log.warn("Failed to parse phone number %@, error: \(error.localizedDescription)", privateArgs: [originalPhoneNumber])
            let cachedPhoneNumber = CCMPhoneNumber(formattedNumber: originalPhoneNumber,
                                                   sanitizedOriginal: sanitizedOriginal,
                                                   labelKey: labeledNumber.label,
                                                   insertInto: context)
            cachedPhoneNumber.cachedContact = cachedContact
          }
        }
      }
      let changeDesc = context.changesDescription()
      log.debug("Contact cache changes: \(changeDesc)")
      try context.saveRecursively()

      let previousCount = (i * batchSize)
      let cumulativeCount = previousCount + batch.count
      progress?(cumulativeCount, totalContactCount)
    }
  }

  func phoneNumberCount(in context: NSManagedObjectContext) throws -> Int {
    let fetchRequest: NSFetchRequest<CCMPhoneNumber> = CCMPhoneNumber.fetchRequest()
    fetchRequest.resultType = .countResultType
    return try context.count(for: fetchRequest)
  }

  /// Uses cascade deletions and saving deletions in batches
  /// because nullify rules don't play well with batch deletions.
  func deleteSystemContactData(in context: NSManagedObjectContext) throws {
    let allContacts = try CCMContact.findAll(in: context)
    let allMetadata = try CCMValidatedMetadata.findAll(in: context)
    let allObjects: [NSManagedObject] = allContacts + allMetadata
    let batches = allObjects.chunked(by: 300)
    for batch in batches {
      batch.forEach { context.delete($0) }
      try context.saveRecursively()
    }
  }

  private func createCachedPhoneNumber(for parsedNumber: PhoneNumber,
                                       sanitizedOriginal: String,
                                       labelKey: String?,
                                       dependencies inputs: CachedPhoneNumberDependencies,
                                       in context: NSManagedObjectContext) -> CCMPhoneNumber {
    // Create inputs
    let globalNumber = GlobalPhoneNumber(parsedNumber: parsedNumber)
    let hashedNumber = inputs.hasher.hash(phoneNumber: globalNumber, salt: inputs.salt, parsedNumber: parsedNumber)
    let formattedNumber = self.format(number: parsedNumber, deviceCountryCode: inputs.deviceCountryCode)

    // Create new CCMPhoneNumber
    let cachedPhoneNumber = CCMPhoneNumber(formattedNumber: formattedNumber,
                                           sanitizedOriginal: sanitizedOriginal,
                                           labelKey: labelKey,
                                           insertInto: context)

    // Find or create CCMValidatedMetadata, attach it to the CCMPhoneNumber
    if let foundMetadata = CCMValidatedMetadata.find(withNumber: globalNumber, in: context) {
      cachedPhoneNumber.cachedValidatedMetadata = foundMetadata
    } else {
      let newMetadata = CCMValidatedMetadata(phoneNumber: globalNumber, hashedGlobalNumber: hashedNumber, insertInto: context)
      cachedPhoneNumber.cachedValidatedMetadata = newMetadata
    }

    return cachedPhoneNumber
  }

  private func format(number: PhoneNumber, deviceCountryCode: Int) -> String {
    let numberIsInternational = deviceCountryCode != Int(number.countryCode)
    let formatType: PhoneNumberFormat = numberIsInternational ? .international : .national
    return phoneNumberKit.format(number, toType: formatType)
  }

}
