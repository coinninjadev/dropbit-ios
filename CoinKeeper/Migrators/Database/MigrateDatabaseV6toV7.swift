//
//  MigrateDatabaseV6toV7.swift
//  DropBit
//
//  Created by Ben Winters on 8/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

struct MigrateDatabaseV6toV7: Migratable {
  let persistenceManager: PersistenceManagerType
  let context: NSManagedObjectContext

  func isMigrated() -> Bool {
    return persistenceManager.brokers.migration.databaseMigrationFlag(for: .v6tov7)
  }

  func migrate() {
    let allTransactions = CKMTransaction.findAll(in: context)

    // update transactions
    for tx in allTransactions {
      // update invitation side before tx.isIncoming
      if let invitation = tx.invitation {
        let isIncoming = invitation.fees == 1 //default value is 1, receiver doesn't update it
        invitation.side = isIncoming ? .receiver : .sender
      }

      tx.isIncoming = tx.calculateIsIncoming(in: context)

      let isSentToSelf = tx.calculateIsSentToSelf(in: context)
      tx.isSentToSelf = isSentToSelf

      if isSentToSelf {
        tx.isIncoming = false
      }
    }

    // set migrated flag
    persistenceManager.brokers.migration.setDatabaseMigrationFlag(migrated: true, for: .v6tov7)
  }
}
