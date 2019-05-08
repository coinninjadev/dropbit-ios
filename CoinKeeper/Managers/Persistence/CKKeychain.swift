//
//  CKKeychain.swift
//  DropBit
//
//  Created by Ben Winters on 3/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Strongbox

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

  let store: KeychainAccessorType

  required init(store: KeychainAccessorType = Strongbox()) {
    self.store = store
  }

  @discardableResult
  func store(anyValue value: Any?, key: CKKeychain.Key) -> Bool {
    return store.archive(value, key: key.rawValue)
  }

  @discardableResult
  func store(valueToHash value: String?, key: CKKeychain.Key) -> Bool {
    return store.archive(value?.sha256(), key: key.rawValue)
  }

  @discardableResult
  func store(deviceID: String) -> Bool {
    return store.archive(deviceID, key: CKKeychain.Key.deviceID.rawValue)
  }

  @discardableResult
  func store(oauthCredentials: TwitterOAuthStorage) -> Bool {
    var success = store.archive(oauthCredentials.twitterOAuthToken, key: CKKeychain.Key.twitterOAuthToken.rawValue)
    success = success || store.archive(oauthCredentials.twitterOAuthTokenSecret, key: CKKeychain.Key.twitterOAuthTokenSecret.rawValue)
    success = success || store.archive(oauthCredentials.twitterUserId, key: CKKeychain.Key.twitterUserId.rawValue)
    success = success || store.archive(oauthCredentials.twitterScreenName, key: CKKeychain.Key.twitterScreenName.rawValue)
    return success
  }

  func oauthCredentials() -> TwitterOAuthStorage? {
    guard let token = store.unarchive(objectForKey: CKKeychain.Key.twitterOAuthToken) as? String,
          let tokenSecret = store.unarchive(objectForKey: CKKeychain.Key.twitterOAuthTokenSecret) as? String,
          let userId = store.unarchive(objectForKey: CKKeychain.Key.twitterUserId) as? String,
          let screenName = store.unarchive(objectForKey: CKKeychain.Key.twitterScreenName) as? String else { return nil }
    return TwitterOAuthStorage(twitterOAuthToken: token, twitterOAuthTokenSecret: tokenSecret, twitterUserId: userId, twitterScreenName: screenName)
  }

  func backup(recoveryWords words: [String]) {
    _ = store.archive(words, key: CKKeychain.Key.walletWords.rawValue)
  }

  @discardableResult
  func store(recoveryWords words: [String]) -> Bool {
    if let pin = tempPinHashStorage { // store pin and wallet together
      _ = store.archive(pin, key: CKKeychain.Key.userPin.rawValue)
      tempPinHashStorage = nil
      return store.archive(words, key: CKKeychain.Key.walletWords.rawValue)
    } else {
      tempWordStorage = words
      return false
    }
  }

  func walletWordsBackedUp() -> Bool {
    return bool(for: .walletWordsBackedUp) ?? false
  }

  @discardableResult
  func store(userPin pin: String) -> Bool {
    let pinHash = pin.sha256()

    if let words = tempWordStorage { // store pin and wallet together
      _ = store.archive(words, key: CKKeychain.Key.walletWords.rawValue)
      tempWordStorage = nil
      return store.archive(pinHash, key: CKKeychain.Key.userPin.rawValue)
    } else {
      tempPinHashStorage = pinHash
      return false
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

  func unverifyUser() {
    self.store(anyValue: nil, key: .countryCode)
    self.store(anyValue: nil, key: .phoneNumber)

    // Prevent reprompting user to verify on next launch
    self.store(anyValue: true, key: .skippedVerification)
  }

}
