//
//  CKKeychain.swift
//  DropBit
//
//  Created by Ben Winters on 3/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Strongbox
import PromiseKit

class CKKeychain: PersistenceKeychainType {

  enum Key: String, CaseIterable {
    case userPin
    case deviceID
    case walletWords
    case walletWordsBackedUp // Bool as NSNumber
    case skippedVerification // Bool as NSNumber
    case lastTimeEnteredBackground
    case countryCode
    case phoneNumber
    case lockoutDate
    case twitterOAuthToken
    case twitterOAuthTokenSecret
    case twitterUserId
    case twitterScreenName
  }

  private var tempWordStorage: [String]?
  private var tempPinHashStorage: String?

  private let serialQueue = DispatchQueue(label: "com.coinkeeper.ckkeychain.serial")

  let store: KeychainAccessorType

  required init(store: KeychainAccessorType = Strongbox()) {
    self.store = store
  }

  @discardableResult
  func storeSynchronously(anyValue value: Any?, key: CKKeychain.Key) -> Bool {
    return self.store.archive(value, key: key.rawValue)
  }

  @discardableResult
  func store(anyValue value: Any?, key: CKKeychain.Key) -> Promise<Void> {
    return storeOnSerialBackgroundQueue(value: value, key: key.rawValue)
  }

  @discardableResult
  func store(valueToHash value: String?, key: CKKeychain.Key) -> Promise<Void> {
    return storeOnSerialBackgroundQueue(value: value?.sha256(), key: key.rawValue)
  }

  @discardableResult
  func store(deviceID: String) -> Promise<Void> {
    return storeOnSerialBackgroundQueue(value: deviceID, key: CKKeychain.Key.deviceID.rawValue)
  }

  func backup(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    return storeOnSerialBackgroundQueue(value: words, key: CKKeychain.Key.walletWords.rawValue)
      .then { self.storeWalletWordsBackedUp(isBackedUp) }
  }

  /// Apple advises to avoid accessing the keychain concurrently, but it is thread-safe
  private func storeOnSerialBackgroundQueue(value: Any?, key: String) -> Promise<Void> {
    return Promise { seal in
      self.serialQueue.async {
        let success = self.store.archive(value, key: key)

        DispatchQueue.main.async {
          if success {
            seal.fulfill(())
          } else {
            seal.reject(CKPersistenceError.keychainWriteFailed(key: key))
          }
        }
      }
    }
  }

  @discardableResult
  func store(oauthCredentials: TwitterOAuthStorage) -> Bool {
    let success1 = store.archive(oauthCredentials.twitterOAuthToken, key: CKKeychain.Key.twitterOAuthToken.rawValue)
    let success2 = store.archive(oauthCredentials.twitterOAuthTokenSecret, key: CKKeychain.Key.twitterOAuthTokenSecret.rawValue)
    let success3 = store.archive(oauthCredentials.twitterUserId, key: CKKeychain.Key.twitterUserId.rawValue)
    let success4 = store.archive(oauthCredentials.twitterScreenName, key: CKKeychain.Key.twitterScreenName.rawValue)
    return success1 || success2 || success3 || success4
  }

  func oauthCredentials() -> TwitterOAuthStorage? {
    guard let token = store.unarchive(objectForKey: CKKeychain.Key.twitterOAuthToken.rawValue) as? String,
          let tokenSecret = store.unarchive(objectForKey: CKKeychain.Key.twitterOAuthTokenSecret.rawValue) as? String,
          let userId = store.unarchive(objectForKey: CKKeychain.Key.twitterUserId.rawValue) as? String,
          let screenName = store.unarchive(objectForKey: CKKeychain.Key.twitterScreenName.rawValue) as? String else { return nil }
    return TwitterOAuthStorage(twitterOAuthToken: token, twitterOAuthTokenSecret: tokenSecret, twitterUserId: userId, twitterScreenName: screenName)
  }

  func backup(recoveryWords words: [String]) {
    _ = store.archive(words, key: CKKeychain.Key.walletWords.rawValue)
  }

  @discardableResult
  func store(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    if let pin = tempPinHashStorage { // store pin and wallet together
      return storeOnSerialBackgroundQueue(value: pin, key: CKKeychain.Key.userPin.rawValue)
        .get { self.tempPinHashStorage = nil }
        .then { self.storeOnSerialBackgroundQueue(value: words, key: CKKeychain.Key.walletWords.rawValue) }
        .then { self.storeWalletWordsBackedUp(isBackedUp) }

    } else {
      tempWordStorage = words
      return self.storeWalletWordsBackedUp(isBackedUp)
    }
  }

  private func storeWalletWordsBackedUp(_ isBackedUp: Bool) -> Promise<Void> {
    return self.storeOnSerialBackgroundQueue(value: NSNumber(value: isBackedUp),
                                             key: CKKeychain.Key.walletWordsBackedUp.rawValue)
  }

  func walletWordsBackedUp() -> Bool {
    return bool(for: .walletWordsBackedUp) ?? false
  }

  @discardableResult
  func store(userPin pin: String) -> Promise<Void> {
    let pinHash = pin.sha256()

    if let words = tempWordStorage { // store pin and wallet together
      return storeOnSerialBackgroundQueue(value: words, key: CKKeychain.Key.walletWords.rawValue)
        .get { self.tempWordStorage = nil }
        .then { self.storeOnSerialBackgroundQueue(value: pinHash, key: CKKeychain.Key.userPin.rawValue) }
    } else {
      tempPinHashStorage = pinHash
      return Promise.value(())
    }
  }

  func retrieveValue(for key: CKKeychain.Key) -> Any? {
    return store.unarchive(objectForKey: key.rawValue)
  }

  func bool(for key: CKKeychain.Key) -> Bool? {
    return store.unarchive(objectForKey: key.rawValue) as? Bool
  }

  func deleteAll() {
    Key.allCases.forEach { self.store(anyValue: nil, key: $0) }
  }

  func unverifyUser(for identity: UserIdentityType) {
    var keys: [CKKeychain.Key] = []
    switch identity {
    case .phone: keys = [.countryCode, .phoneNumber]
    case .twitter: keys = [.twitterUserId, .twitterScreenName, .twitterOAuthToken, .twitterOAuthTokenSecret]
    }
    keys.forEach { self.store(anyValue: nil, key: $0) }

    // Prevent reprompting user to verify on next launch
    self.store(anyValue: true, key: .skippedVerification)
  }

}
