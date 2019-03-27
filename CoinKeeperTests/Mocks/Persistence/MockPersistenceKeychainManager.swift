//
//  MockPersistenceKeychainManager.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockPersistenceKeychainManager: PersistenceKeychainType {
  func backup(recoveryWords words: [String]) {}
  func deleteAll() {}
  func unverifyUser() {}

  func bool(for key: CKKeychain.Key) -> Bool? {
    return nil
  }

  func walletWordsBackedUp() -> Bool {
    return bool(for: .walletWordsBackedUp) ?? false
  }

  required init(store: KeychainAccessorType) { }

  var valueExists = false
  var values: [String: Any] = [:]
  var anyValueExists = false

  func store(anyValue value: Any?, key: CKKeychain.Key) -> Bool {
    self.values[key.rawValue] = value
    anyValueExists = (self.values[key.rawValue] != nil)
    return anyValueExists
  }
  func store(valueToHash value: String?, key: CKKeychain.Key) -> Bool {
    self.values[key.rawValue] = value
    valueExists = (self.values[key.rawValue] != nil)
    return valueExists
  }

  var wordsExist = false
  func store(recoveryWords words: [String]) -> Bool {
    self.values[CKKeychain.Key.walletWords.rawValue] = words
    wordsExist = !words.isEmpty
    return wordsExist
  }

  var userPinExists = false
  func store(userPin: String) -> Bool {
    return true
  }

  var deviceIDExists = false
  func store(deviceID: String) -> Bool {
    self.values[CKKeychain.Key.deviceID.rawValue] = deviceID
    deviceIDExists = !deviceID.isEmpty
    return deviceIDExists
  }

  func retrieveValue(for key: CKKeychain.Key) -> Any? {
    return values[key.rawValue]
  }

}

class MockKeychainAccessorType: KeychainAccessorType {
  var wasAskedToArchive = false
  var wasAskedToUnarchive = false

  var value: [String: Any] = [:]

  func archive(_ value: Any?, key: String) -> Bool {
    wasAskedToArchive = true
    self.value[key] = value
    return true
  }

  func unarchive(objectForKey: String) -> Any? {
    wasAskedToUnarchive = true
    return self.value[objectForKey]
  }
}
