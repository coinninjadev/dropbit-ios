//
//  MockMigrationBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockMigrationBroker: CKPersistenceBroker, MigrationBrokerType {

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion) { }

  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool {
    return false
  }

  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion) { }

  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool {
    return false
  }

  func contactCacheMigrationFlag(for version: ContactCacheMigrationVersion) -> Bool {
    return false
  }

  func setContactCacheMigrationFlag(migrated: Bool, for version: ContactCacheMigrationVersion) { }

}
