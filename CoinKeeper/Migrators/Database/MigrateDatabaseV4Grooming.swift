//
//  MigrateDatabaseV4Grooming.swift
//  DropBit
//
//  Created by BJ Miller on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

struct MigrateDatabaseV4Grooming: Migratable {

  let persistenceManager: PersistenceManagerType
  let context: NSManagedObjectContext

  func isMigrated() -> Bool {
    return persistenceManager.databaseMigrationFlag(for: .v4Grooming)
  }

  func migrate() {
    let allPhoneNumbers = CKMPhoneNumber.findAll(in: context)

    // filter items into dictionary where key is e164 representation
    var itemsById: [String: [CKMPhoneNumber]] = [:]
    allPhoneNumbers.forEach { number in
      let globalNumber = GlobalPhoneNumber(countryCode: Int(number.countryCode), nationalNumber: "\(number.number)")
      let identifier = globalNumber.asE164()
      let items = (itemsById[identifier] ?? []).appending(element: number)
      itemsById[identifier] = items
    }

    // create new single objects and delete old
    itemsById.forEach { (_, value: [CKMPhoneNumber]) in
      let newNumber = CKMPhoneNumber(insertInto: context)
      value.forEach { (number: CKMPhoneNumber) in
        newNumber.countryCode = number.countryCode
        newNumber.number = number.number
        number.status.map { newNumber.status = $0 }
        number.phoneNumberHash.asNilIfEmpty().map { newNumber.phoneNumberHash = $0 }
        number.counterparty.map { newNumber.counterparty = $0 }
        newNumber.invitations = newNumber.invitations.union(number.invitations)
        newNumber.transactions = newNumber.transactions.union(number.transactions)
      }
    }

    // delete all previous instances of CKMPhoneNumber
    allPhoneNumbers.forEach { context.delete($0) }

    // set migrated flag
    persistenceManager.setDatabaseMigrationFlag(migrated: true, for: .v4Grooming)
  }
}
