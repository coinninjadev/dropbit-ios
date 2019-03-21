//
//  ContactCacheMigratorFactory.swift
//  DropBit
//
//  Created by Ben Winters on 3/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import os.log

enum ContactCacheMigrationVersion: String {
  case v1tov2
}

struct ContactCacheMigratorFactory {
  let persistenceManager: PersistenceManagerType
  let dataWorker: ContactCacheDataWorkerType

  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.ContactCacheMigratorFactory", category: "migration")

  func migrators() -> [Migratable] {
    let v1tov2 = MigrateContactCacheV1toV2(persistenceManager: persistenceManager,
                                           dataWorker: dataWorker,
                                           logger: logger)
    return [v1tov2]
  }
}
