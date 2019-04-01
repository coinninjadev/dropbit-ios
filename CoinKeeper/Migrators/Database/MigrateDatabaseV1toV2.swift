//
//  MigrateV1toV2.swift
//  DropBit
//
//  Created by BJ Miller on 12/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

struct MigrateDatabaseV1toV2: Migratable {
  let persistenceManager: PersistenceManagerType
  let addressDataSource: AddressDataSourceType
  let context: NSManagedObjectContext

  func isMigrated() -> Bool {
    return persistenceManager.databaseMigrationFlag(for: .v1tov2)
  }

  func migrate() {
    let allTransactions = CKMTransaction.findAll(in: context)

    // update vins
    let allVins = allTransactions.flatMap { $0.vins }
    for vin in allVins {
      vin.updateBelongsToWallet(in: context)
    }

    // update transactions
    for transaction in allTransactions {
      transaction.isIncoming = transaction.calculateIsIncoming(in: context)

      let isSentToSelf = transaction.calculateIsSentToSelf(in: context)
      transaction.isSentToSelf = isSentToSelf

      if isSentToSelf {
        transaction.isIncoming = false
      }
    }

    // set migrated flag
    persistenceManager.setDatabaseMigrationFlag(migrated: true, for: .v1tov2)
  }
}
