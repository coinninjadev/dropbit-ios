//
//  MigrateKeychainV1toV2.swift
//  DropBit
//
//  Created by Ben Winters on 1/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MigrateKeychainV1toV2: Migratable {

  let persistenceManager: PersistenceManagerType

  func migrate() {
    let version = KeychainMigrationVersion.v1tov2
    let migrated = persistenceManager.keychainMigrationFlag(for: version)
    guard !migrated else { return }

    let allKeys = CKKeychain.Key.allCases

    for key in allKeys {
      guard let existingValue = persistenceManager.keychainManager.retrieveValue(for: key) else { continue }

      // store nil before changing accessibility to avoid errors
      persistenceManager.keychainManager.store(anyValue: nil, key: key)

      // re-store the value, which will store it with the current accessibility level
      persistenceManager.keychainManager.store(anyValue: existingValue, key: key)
    }

    persistenceManager.setKeychainMigrationFlag(migrated: true, for: version)
  }

}
