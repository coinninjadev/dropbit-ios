//
//  MigrateContactCacheV1toV2.swift
//  DropBit
//
//  Created by Ben Winters on 3/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

struct MigrateContactCacheV1toV2: Migratable {
  let persistenceManager: PersistenceManagerType
  let dataWorker: ContactCacheDataWorkerType

  func isMigrated() -> Bool {
    return persistenceManager.brokers.migration.contactCacheMigrationFlag(for: .v1tov2)
  }

  func migrate() {
    dataWorker.reloadSystemContactsIfNeeded(force: true) { error in
      if let error = error {
        log.error(error, message: "Failed to force reload contact cache")
      } else {
        self.persistenceManager.brokers.migration.setContactCacheMigrationFlag(migrated: true, for: .v1tov2)
      }
    }
  }
}
