//
//  CKMCounterpartyAddress+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 5/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMCounterpartyAddress)
public class CKMCounterpartyAddress: NSManagedObject {

  public convenience init(address: String, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.addressId = address
  }

  static func findOrCreate(withAddress address: String, in context: NSManagedObjectContext) -> CKMCounterpartyAddress {
    var ckmCounterpartyAddress: CKMCounterpartyAddress!
    context.performAndWait {
      if let foundAddress = find(withAddress: address, in: context) {
        ckmCounterpartyAddress = foundAddress
      } else {
        ckmCounterpartyAddress = CKMCounterpartyAddress(address: address, insertInto: context)
      }
    }
    return ckmCounterpartyAddress
  }

  static func find(withAddress address: String, in context: NSManagedObjectContext) -> CKMCounterpartyAddress? {
    let fetchRequest: NSFetchRequest<CKMCounterpartyAddress> = CKMCounterpartyAddress.fetchRequest()
    let path = #keyPath(CKMCounterpartyAddress.addressId)
    fetchRequest.predicate = NSPredicate(format: "\(path) == %@", address)
    fetchRequest.fetchLimit = 1

    var theAddress: CKMCounterpartyAddress?

    context.performAndWait {
      do {
        theAddress = try context.fetch(fetchRequest).first
      } catch {
        theAddress = nil
      }
    }

    return theAddress
  }

}
