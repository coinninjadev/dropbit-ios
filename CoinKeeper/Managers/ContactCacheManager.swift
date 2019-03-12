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
import os.log
import PhoneNumberKit

protocol ContactCacheManagerType: AnyObject {

  var viewContext: NSManagedObjectContext { get }
  func createChildBackgroundContext() -> NSManagedObjectContext

  func createPhoneNumberFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber>
  func predicate(forSearch searchText: String) -> NSPredicate

  func phoneNumberCount(in context: NSManagedObjectContext) throws -> Int
  func allValidatedMetadata(in context: NSManagedObjectContext) throws -> [CCMValidatedMetadata]
  func allCachedContacts(in context: NSManagedObjectContext) throws -> [CCMContact]

  func deleteSystemContactData(in context: NSManagedObjectContext) throws
  func persistContacts(_ contacts: [CNContact],
                       inputs: CachedPhoneNumberDependencies,
                       in context: NSManagedObjectContext) throws

  func managedContactComponents(forGlobalPhoneNumber number: GlobalPhoneNumber) -> ManagedContactComponents?

}

class ContactCacheManager: NSPersistentContainer, ContactCacheManagerType {

  static let modelFilename = "ContactCacheDB"

  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.contactcache", category: "manager")

  static var model: NSManagedObjectModel? = {
    return Bundle(for: ContactCacheManager.self).url(forResource: "ContactCache", withExtension: "momd")
      .flatMap { NSManagedObjectModel(contentsOf: $0) }
  }()

  convenience init() {
    self.init(stackConfig: CoreDataStackConfig(stackType: .contactCache, storeType: .disk))
  }

  convenience init(stackConfig: CoreDataStackConfig) {
    let maybeModel = Bundle(for: ContactCacheManager.self)
      .url(forResource: stackConfig.stackType.modelName, withExtension: "momd")
      .flatMap { NSManagedObjectModel(contentsOf: $0) }
    guard let model = maybeModel else { fatalError() }
    self.init(name: stackConfig.stackType.modelName, managedObjectModel: model)
    setupPersistentStores(stackConfig: stackConfig)
    self.viewContext.automaticallyMergesChangesFromParent = true
    self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  func createChildBackgroundContext() -> NSManagedObjectContext {
    let bgContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    bgContext.parent = viewContext
    bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return bgContext
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

  func managedContactComponents(forGlobalPhoneNumber number: GlobalPhoneNumber) -> ManagedContactComponents? {
    var components: ManagedContactComponents?
    if let foundMetadata = CCMValidatedMetadata.find(withNumber: number, in: viewContext),
      let displayName = foundMetadata.cachedPhoneNumber?.cachedContact?.displayName,
      let phoneInputs = ManagedPhoneNumberInputs(countryCode: foundMetadata.countryCode, nationalNumber: foundMetadata.nationalNumber) {
      let counterpartyInputs = ManagedCounterpartyInputs(name: displayName)
      components = ManagedContactComponents(counterpartyInputs: counterpartyInputs, phonenumberInputs: phoneInputs)
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

    let notWorkPredicate = NSPredicate(format: "\(#keyPath(CCMPhoneNumber.labelKey)) != %@", CNLabelWork)
    return NSCompoundPredicate(type: .and, subpredicates: [hasNamePredicate,
                                                           notSpamPredicate,
                                                           notWorkPredicate])
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
                       in context: NSManagedObjectContext) throws {

    for contact in contacts {
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
          let parsedNumber = try inputs.kit.parse(sanitizedForParsing, ignoreType: false)
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
          os_log("Failed to parse phone number %{private}@, reason: %@", log: self.logger,
                 type: .error, originalPhoneNumber, error.localizedDescription)
          let cachedPhoneNumber = CCMPhoneNumber(formattedNumber: originalPhoneNumber,
                                                 sanitizedOriginal: sanitizedOriginal,
                                                 labelKey: labeledNumber.label,
                                                 insertInto: context)
          cachedPhoneNumber.cachedContact = cachedContact
        }
      }
    }
  }

  func phoneNumberCount(in context: NSManagedObjectContext) throws -> Int {
    let fetchRequest: NSFetchRequest<CCMPhoneNumber> = CCMPhoneNumber.fetchRequest()
    fetchRequest.resultType = .countResultType
    return try context.count(for: fetchRequest)
  }

  func deleteSystemContactData(in context: NSManagedObjectContext) throws {
    let entitiesToKeep = [String(describing: CCMValidatedMetadata.self)]
    try context.performThrowingAndWait {
      let entitiesToDelete = ContactCacheManager.model?.entities
        .compactMap { $0.name }.filter { !entitiesToKeep.contains($0) } ?? []
      try entitiesToDelete.forEach { entityName in
        try self.executeBatchDeleteFor(entity: entityName, in: context)
      }
    }
  }

  // MARK: - Private

  private func setupPersistentStores(stackConfig: CoreDataStackConfig) {
    let directory = NSPersistentContainer.defaultDirectoryURL()
    let storeURL = directory.appendingPathComponent("\(stackConfig.stackType.modelName).sqlite")
    let description = NSPersistentStoreDescription(url: storeURL)
    description.shouldInferMappingModelAutomatically = true
    description.shouldMigrateStoreAutomatically = true
    description.type = stackConfig.storeType.storeType
    description.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject, forKey: NSPersistentStoreFileProtectionKey)
    persistentStoreDescriptions = [description]

    self.loadPersistentStores { [weak self] _, error in
      guard let strongSelf = self else { fatalError("could not load contact cache persistent store") }
      if let err = error {
        os_log("Failed to load contact cache persistence stores: %@", log: strongSelf.logger, type: .error, err.localizedDescription)
      }
    }
  }

  private func executeBatchDeleteFor(entity name: String, in context: NSManagedObjectContext) throws {
    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
    let request = NSBatchDeleteRequest(fetchRequest: fetch)
    request.resultType = .resultTypeObjectIDs

    try context.performThrowingAndWait {
      if let result = try context.execute(request) as? NSBatchDeleteResult, let objectIDs = result.result as? [NSManagedObjectID] {
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [context])
      }
    }
  }

  private func createCachedPhoneNumber(for parsedNumber: PhoneNumber,
                                       sanitizedOriginal: String,
                                       labelKey: String?,
                                       dependencies inputs: CachedPhoneNumberDependencies,
                                       in context: NSManagedObjectContext) -> CCMPhoneNumber {
    // Create inputs
    let globalNumber = GlobalPhoneNumber(parsedNumber: parsedNumber)
    let hashedNumber = inputs.hasher.hash(phoneNumber: globalNumber, salt: inputs.salt)
    let formattedNumber = self.format(number: parsedNumber, kit: inputs.kit, deviceCountryCode: inputs.deviceCountryCode)

    // Create new CCMPhoneNumber
    let cachedPhoneNumber = CCMPhoneNumber(formattedNumber: formattedNumber,
                                           sanitizedOriginal: sanitizedOriginal,
                                           labelKey: labelKey,
                                           insertInto: context)

    // Find or create CCMValidatedMetadata, attach it to the CCMPhoneNumber
    if let foundMetadata = CCMValidatedMetadata.find(withNumber: globalNumber, in: context) {
      foundMetadata.cachedPhoneNumber = cachedPhoneNumber
    } else {
      let newMetadata = CCMValidatedMetadata(phoneNumber: globalNumber, hashedGlobalNumber: hashedNumber, insertInto: context)
      newMetadata.cachedPhoneNumber = cachedPhoneNumber
    }

    return cachedPhoneNumber
  }

  private func format(number: PhoneNumber, kit: PhoneNumberKit, deviceCountryCode: Int) -> String {
    let numberIsInternational = deviceCountryCode != Int(number.countryCode)
    let formatType: PhoneNumberFormat = numberIsInternational ? .international : .national
    return kit.format(number, toType: formatType)
  }

}
