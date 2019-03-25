//
//  DatabaseMigratorFactory.swift
//  DropBit
//
//  Created by BJ Miller on 12/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

struct DatabaseMigratorFactory {
  let persistenceManager: PersistenceManagerType
  let addressDataSource: AddressDataSourceType
  let context: NSManagedObjectContext

  func migrators() -> [Migratable] {
    let v1tov2 = MigrateDatabaseV1toV2(persistenceManager: persistenceManager, addressDataSource: addressDataSource, context: context)
    let v4Grooming = MigrateDatabaseV4Grooming(persistenceManager: persistenceManager, context: context)

    return [v1tov2, v4Grooming]
  }
}
