//
//  ContactCacheMigratorFactory.swift
//  DropBit
//
//  Created by Ben Winters on 3/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

enum ContactCacheMigrationVersion: String {
  case v1tov2
}

struct ContactCacheMigratorFactory {
  let persistenceManager: PersistenceManagerType
  let dataWorker: ContactCacheDataWorkerType

  func migrators() -> [Migratable] {
    let v1tov2 = MigrateContactCacheV1toV2(persistenceManager: persistenceManager,
                                           dataWorker: dataWorker)
    return [v1tov2]
  }
}
