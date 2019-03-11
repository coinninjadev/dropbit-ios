//
//  KeychainMigratorFactory.swift
//  DropBit
//
//  Created by Ben Winters on 1/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct KeychainMigratorFactory {
  let persistenceManager: PersistenceManagerType

  func migrators() -> [Migratable] {
    let v1tov2 = MigrateKeychainV1toV2(persistenceManager: persistenceManager)
    return [v1tov2]
  }
}
