//
//  CKMCounterparty+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMCounterparty)
public class CKMCounterparty: NSManagedObject {

  public convenience init(name: String, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.name = name
  }

  static func findOrCreate(with name: String, in context: NSManagedObjectContext) -> CKMCounterparty {
    let counterpartyNameFetchRequest: NSFetchRequest<CKMCounterparty> = CKMCounterparty.fetchRequest()
    let nameKeyPath = #keyPath(CKMCounterparty.name)
    let counterpartyNamePredicate = NSPredicate(format: "\(nameKeyPath) = %@", name)
    counterpartyNameFetchRequest.predicate = counterpartyNamePredicate

    var counterparty: CKMCounterparty!

    context.performAndWait {
      do {
        if let counterpartyName = try context.fetch(counterpartyNameFetchRequest).first {
          counterparty = counterpartyName
        } else {
          counterparty = CKMCounterparty(name: name, insertInto: context)
        }
      } catch {
        counterparty = CKMCounterparty(name: name, insertInto: context)
      }
    }

    return counterparty
  }

}
