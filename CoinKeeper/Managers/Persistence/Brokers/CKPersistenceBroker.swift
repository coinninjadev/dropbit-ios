//
//  CKPersistenceBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CKPersistenceBroker {

  let keychainManager: PersistenceKeychainType
  let databaseManager: PersistenceDatabaseType
  let userDefaultsManager: PersistenceUserDefaultsType

  init(
    keychainManager: PersistenceKeychainType,
    databaseManager: PersistenceDatabaseType,
    userDefaultsManager: PersistenceUserDefaultsType) {
    self.keychainManager = keychainManager
    self.databaseManager = databaseManager
    self.userDefaultsManager = userDefaultsManager
  }

}
