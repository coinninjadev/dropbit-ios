//
//  MigrateContactCacheV1toV2.swift
//  DropBit
//
//  Created by Ben Winters on 3/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import os.log

struct MigrateContactCacheV1toV2: Migratable {
  let persistenceManager: PersistenceManagerType
  let dataWorker: ContactCacheDataWorkerType
  let logger: OSLog

  func migrate() {
    let migrated = persistenceManager.contactCacheMigrationFlag(for: .v1tov2)
    guard !migrated else { return }

    dataWorker.reloadSystemContactsIfNeeded(force: true) { error in
      if let error = error {
        os_log("Failed to force reload contact cache: %@", log: self.logger, type: .error, error.localizedDescription)
      } else {
        self.persistenceManager.setContactCacheMigrationFlag(migrated: true, for: .v1tov2)
      }
    }
  }

}
