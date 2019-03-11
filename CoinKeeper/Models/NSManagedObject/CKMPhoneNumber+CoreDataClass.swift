//
//  CKMPhoneNumber+CoreDataClass.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMPhoneNumber)
public class CKMPhoneNumber: NSManagedObject {

  public convenience init?(phoneNumber: GlobalPhoneNumber, insertInto context: NSManagedObjectContext) {
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) else { return nil }
    self.init(inputs: inputs, insertInto: context)
  }

  public convenience init?(metadataParticipant participant: MetadataParticipant, insertInto context: NSManagedObjectContext) {
    guard let countryCode = participant.countryCode,
      let nationalNumber = participant.phoneNumber
      else { return nil }
    let globalNumber = GlobalPhoneNumber(countryCode: countryCode, nationalNumber: nationalNumber)
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: globalNumber) else { return nil }
    self.init(inputs: inputs, insertInto: context)
  }

  private convenience init(inputs: ManagedPhoneNumberInputs, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.countryCode = inputs.countryCode
    self.number = inputs.nationalNumber
  }

  public static func findOrCreate(withInputs inputs: ManagedPhoneNumberInputs,
                                  phoneNumberHash: String,
                                  in context: NSManagedObjectContext) -> CKMPhoneNumber {
    let number = find(withInputs: inputs, in: context) ?? CKMPhoneNumber(inputs: inputs, insertInto: context)
    number.phoneNumberHash = phoneNumberHash
    return number
  }

  public static func find(withInputs inputs: ManagedPhoneNumberInputs, in context: NSManagedObjectContext) -> CKMPhoneNumber? {
    let ccPath = #keyPath(CKMPhoneNumber.countryCode)
    let ccPredicate = NSPredicate(format: "\(ccPath) == %d", inputs.countryCode)
    let numberPath = #keyPath(CKMPhoneNumber.number)
    let numberPredicate = NSPredicate(format: "\(numberPath) == %d", inputs.nationalNumber)
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
      print("error: \(error)")
    }
    return result
  }

  public func configure(with outgoingTransactionData: OutgoingTransactionData, in context: NSManagedObjectContext) {
    guard outgoingTransactionData.contactName.isNotEmpty else { return }
    self.counterparty = CKMCounterparty.findOrCreate(with: outgoingTransactionData.contactName, in: context)
  }

  var asGlobalPhoneNumber: GlobalPhoneNumber {
    return GlobalPhoneNumber(countryCode: Int(self.countryCode),
                             nationalNumber: "\(self.number)")
  }

}
