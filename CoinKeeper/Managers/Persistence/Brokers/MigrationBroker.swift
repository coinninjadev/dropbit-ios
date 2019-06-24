//
//  MigrationBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class MigrationBroker: CKPersistenceBroker, MigrationBrokerType {

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .migrationVersions)
  }

  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .migrationVersions)
  }

  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .keychainMigrationVersions)
  }

  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .keychainMigrationVersions)
  }

  func contactCacheMigrationFlag(for version: ContactCacheMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .contactCacheMigrationVersions)
  }

  func setContactCacheMigrationFlag(migrated: Bool, for version: ContactCacheMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .contactCacheMigrationVersions)
  }

  private func getMigrationFlag(version: String, key: CKUserDefaults.Key) -> Bool {
    let value = userDefaultsManager.value(for: key) as? [String: Bool]
    return value?[version] ?? false
  }

  private func setMigrationFlag(migrated: Bool, version: String, key: CKUserDefaults.Key) {
    var value = userDefaultsManager.value(for: key) as? [String: Bool] ?? [:]
    value[version] = migrated
    userDefaultsManager.setValue(value, for: key)
  }

}
