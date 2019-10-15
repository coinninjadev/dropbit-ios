//
//  MockPersistenceKeychainManager.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import enum Result.Result
@testable import DropBit

class MockPersistenceKeychainManager: PersistenceKeychainType {
  func prepareForStateDetermination() { }

  func backup(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    return .value(())
  }

  func deleteAll() {}
  func unverifyUser(for identity: UserIdentityType) {}

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

  private func promise(forExistence exists: Bool, key: String) -> Promise<Void> {
    if exists {
      return .value(())
    } else {
      return Promise(error: CKPersistenceError.missingValue(key: key))
    }
  }

  func storeSynchronously(anyValue value: Any?, key: CKKeychain.Key) -> Bool {
    self.values[key.rawValue] = value
    valueExists = (self.values[key.rawValue] != nil)
    return valueExists
  }

  func store(anyValue value: Any?, key: CKKeychain.Key) -> Promise<Void> {
    self.values[key.rawValue] = value
    anyValueExists = (self.values[key.rawValue] != nil)
    return promise(forExistence: anyValueExists, key: key.rawValue)
  }

  func store(valueToHash value: String?, key: CKKeychain.Key) -> Promise<Void> {
    self.values[key.rawValue] = value
    valueExists = (self.values[key.rawValue] != nil)
    return promise(forExistence: valueExists, key: key.rawValue)
  }

  var wordsExist = false
  func store(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    let key = CKKeychain.Key.walletWords.rawValue
    self.values[key] = words
    wordsExist = !words.isEmpty
    return promise(forExistence: wordsExist, key: key)
  }

  var userPinExists = false
  func store(userPin: String) -> Promise<Void> {
    return .value(())
  }

  var deviceIDExists = false
  func store(deviceID: String) -> Promise<Void> {
    let key = CKKeychain.Key.deviceID.rawValue
    self.values[key] = deviceID
    deviceIDExists = !deviceID.isEmpty
    return promise(forExistence: deviceIDExists, key: key)
  }

  func retrieveValue(for key: CKKeychain.Key) -> Any? {
    return values[key.rawValue]
  }

  func store(oauthCredentials: TwitterOAuthStorage) -> Bool {
    return true
  }

  func oauthCredentials() -> TwitterOAuthStorage? {
    return nil
  }

  func storeWalletWordsBackedUp(_ isBackedUp: Bool) -> Promise<Void> {
    return Promise.value(())
  }

  func upgrade(recoveryWords wordsd: [String]) -> Promise<Void> {
    return Promise { _ in }
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
