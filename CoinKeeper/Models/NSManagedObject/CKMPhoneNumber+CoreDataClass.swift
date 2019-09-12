//
//  CKMPhoneNumber+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMPhoneNumber)
public class CKMPhoneNumber: NSManagedObject {

  // for testing
  public convenience init?(phoneNumber: GlobalPhoneNumber, insertInto context: NSManagedObjectContext) {
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) else { return nil }
    self.init(inputs: inputs, insertInto: context)
  }

  static func findOrCreate(withMetadataParticipant participant: MetadataParticipant,
                           in context: NSManagedObjectContext) -> CKMPhoneNumber? {
    guard let globalNumber = GlobalPhoneNumber(participant: participant),
      let inputs = ManagedPhoneNumberInputs(phoneNumber: globalNumber)
      else { return nil }
    return self.findOrCreate(with: inputs, in: context)
  }

  private convenience init(inputs: ManagedPhoneNumberInputs, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.countryCode = inputs.countryCode
    self.number = inputs.nationalNumber
  }

  public static func findAll(in context: NSManagedObjectContext) -> [CKMPhoneNumber] {
    let request: NSFetchRequest<CKMPhoneNumber> = CKMPhoneNumber.fetchRequest()
    var results: [CKMPhoneNumber] = []
    do {
      results = try context.fetch(request)
    } catch {
      results = []
    }
    return results
  }

  public static func findOrCreate(withInputs inputs: ManagedPhoneNumberInputs,
                                  phoneNumberHash: String,
                                  in context: NSManagedObjectContext) -> CKMPhoneNumber {
    let number = findOrCreate(with: inputs, in: context)
    number.phoneNumberHash = phoneNumberHash
    return number
  }

  public static func findOrCreate(with inputs: ManagedPhoneNumberInputs, in context: NSManagedObjectContext) -> CKMPhoneNumber {
    if let number = find(withInputs: inputs, in: context) {
      return number
    } else {
      return CKMPhoneNumber(inputs: inputs, insertInto: context)
    }
  }
  public static func find(withGlobalPhoneNumber number: GlobalPhoneNumber, in context: NSManagedObjectContext) -> CKMPhoneNumber? {
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: number) else { return nil }
    return self.find(withInputs: inputs, in: context)
  }

  public static func find(withInputs inputs: ManagedPhoneNumberInputs, in context: NSManagedObjectContext) -> CKMPhoneNumber? {
    let ccPath = #keyPath(CKMPhoneNumber.countryCode)
    let ccPredicate = NSPredicate(format: "\(ccPath) == \(inputs.countryCode)")
    let numberPath = #keyPath(CKMPhoneNumber.number)
    let numberPredicate = NSPredicate(format: "\(numberPath) == \(inputs.nationalNumber)")
    let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [numberPredicate, ccPredicate])

    let request: NSFetchRequest<CKMPhoneNumber> = CKMPhoneNumber.fetchRequest()
    request.fetchLimit = 1
    request.predicate = combinedPredicate

    var ckmPhoneNumber: CKMPhoneNumber?
    context.performAndWait {
      do {
        let results = try context.fetch(request)
        ckmPhoneNumber = results.first
      } catch {
        ckmPhoneNumber = nil
      }
    }
    return ckmPhoneNumber
  }

  public static func findAllWithoutCounterpartyName(in context: NSManagedObjectContext) -> [CKMPhoneNumber] {
    let counterpartyKeyPath = #keyPath(CKMPhoneNumber.counterparty)
    let counterpartyPredicate = NSPredicate(format: "\(counterpartyKeyPath) == nil")
    let request: NSFetchRequest<CKMPhoneNumber> = CKMPhoneNumber.fetchRequest()
    request.predicate = counterpartyPredicate

    var result: [CKMPhoneNumber] = []
    do {
      result = try context.fetch(request)
    } catch {
      log.error(error, message: nil)
    }
    return result
  }

  public func configure(with outgoingTransactionData: OutgoingTransactionData, in context: NSManagedObjectContext) {
    guard let name = outgoingTransactionData.receiver?.displayName, name.isNotEmpty else { return }
    self.counterparty = CKMCounterparty.findOrCreate(with: name, in: context)
  }

  var asGlobalPhoneNumber: GlobalPhoneNumber {
    return GlobalPhoneNumber(countryCode: Int(self.countryCode),
                             nationalNumber: "\(self.number)")
  }

}
