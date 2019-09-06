//
//  LaunchStateManager.swift
//  CoinKeeper
//
// Created by BJ Miller on 2/26/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LaunchStateManagerType: AnyObject {
  var shouldRequireAuthentication: Bool { get }
  var launchType: LaunchType { get set }
  var skippedVerification: Bool { get }
  var selectedSetupFlow: SetupFlow? { get set }
  var userAuthenticated: Bool { get }
  var upgradeInProgress: Bool { get set }
  init(persistenceManager: PersistenceManagerType)
  func currentProperties() -> LaunchStateProperties
  func profileIsActivated() -> Bool
  func deviceIsVerified() -> Bool
  func pinExists() -> Bool
  func walletExists() -> Bool
  func walletIsBackedUp() -> Bool
  func shouldRegisterWallet() -> Bool
  func userWasAuthenticated()
  func unauthenticateUser()
  func isFirstTime() -> Bool
  func isFirstTimeAfteriCloudRestore() -> Bool
  func needsUpgradedToSegwit() -> Bool
}

/**
 Uses OptionSet to allow users to complete these steps in any order and at any time.
 Each option represents a boolean condition.
 */
struct LaunchStateProperties: OptionSet {
  let rawValue: Int

  static let pinExists = LaunchStateProperties(rawValue: 1 << 0)
  static let walletExists = LaunchStateProperties(rawValue: 1 << 1)
  static let wordsBackedUp = LaunchStateProperties(rawValue: 1 << 2)
  static let deviceVerified = LaunchStateProperties(rawValue: 1 << 3)
  static let databaseWalletExists = LaunchStateProperties(rawValue: 1 << 4)
  static let upgradedToSegwit = LaunchStateProperties(rawValue: 1 << 5)
}

class LaunchStateManager: LaunchStateManagerType {

  private let persistenceManager: PersistenceManagerType
  var launchType: LaunchType = .userInitiated
  var selectedSetupFlow: SetupFlow?
  var upgradeInProgress: Bool = false

  required init(persistenceManager: PersistenceManagerType) {
    self.persistenceManager = persistenceManager
  }

  func walletIsBackedUp() -> Bool {
    return currentProperties().contains(.wordsBackedUp)
  }

  func currentProperties() -> LaunchStateProperties {
    var options: LaunchStateProperties = []

    if persistenceManager.keychainManager.retrieveValue(for: .userPin) != nil {
      options.insert(.pinExists)
    }

    if persistenceManager.brokers.wallet.walletWords() != nil {
      options.insert(.walletExists)
    }

    if let value = persistenceManager.keychainManager.retrieveValue(for: .walletWordsBackedUp) as? NSNumber,
      value.boolValue == true {
      options.insert(.wordsBackedUp)
    }

    let context = persistenceManager.mainQueueContext()
    context.performAndWait {
      if persistenceManager.brokers.user.userVerificationStatus(in: context) == .verified {
        options.insert(.deviceVerified)
      }
      if persistenceManager.databaseManager.walletId(in: context) != nil {
        options.insert(.databaseWalletExists)
      }
    }

    if let words = persistenceManager.keychainManager.retrieveValue(for: .walletWordsV2) as? [String], words.count == 12 {
      options.insert(.upgradedToSegwit)
    }

    return options
  }

  var skippedVerification: Bool {
    if let didSkip = persistenceManager.keychainManager.retrieveValue(for: .skippedVerification) as? NSNumber,
      didSkip.boolValue == true {
      return true
    } else {
      return false
    }
  }

  func pinExists() -> Bool {
    return currentProperties().contains(.pinExists)
  }

  func walletExists() -> Bool {
    return currentProperties().contains(.walletExists)
  }

  /**
   The wallet may still exist in the keychain from a previous installation,
   while the wallet ID is not persisted across installations.
   */
  func shouldRegisterWallet() -> Bool {
    let walletExists = currentProperties().contains(.walletExists)

    let bgContext = persistenceManager.createBackgroundContext()
    let walletIdExists = persistenceManager.brokers.wallet.walletId(in: bgContext) != nil

    log.debug("Wallet exists: \(walletExists), wallet ID exists: \(walletIdExists)")
    return walletExists && !walletIdExists
  }

  func isFirstTime() -> Bool {
    let properties = currentProperties()
    return properties.isEmpty || isFirstTimeAfteriCloudRestore(with: properties)
  }

  func isFirstTimeAfteriCloudRestore() -> Bool {
    return isFirstTimeAfteriCloudRestore(with: currentProperties())
  }

  private func isFirstTimeAfteriCloudRestore(with properties: LaunchStateProperties) -> Bool {
    return properties.contains(.databaseWalletExists) && !properties.contains(.walletExists)
  }

  func deviceIsVerified() -> Bool {
    return currentProperties().contains(.deviceVerified)
  }

  func profileIsActivated() -> Bool {
    let criteria: LaunchStateProperties = [.wordsBackedUp, .deviceVerified]
    let properties = currentProperties()

    let wordsBackedUp = properties.contains(.wordsBackedUp)
    let deviceVerified = properties.contains(.deviceVerified)
    log.debug("Words backed up: \(wordsBackedUp), Device verified: \(deviceVerified)")

    return criteria.isSubset(of: properties)
  }

  func needsUpgradedToSegwit() -> Bool {
    return !currentProperties().contains(.upgradedToSegwit)
  }

  // MARK: In-Memory Status

  /// PIN/Face/Touch ID verification
  private(set) var userAuthenticated: Bool = false

  var shouldRequireAuthentication: Bool {
    guard !isFirstTime(), pinExists() else { return false }
    return !userAuthenticated && launchType == .userInitiated
  }

  func userWasAuthenticated() {
    persistenceManager.brokers.activity.setLastLoginTime()
    userAuthenticated = true
  }

  func unauthenticateUser() {
    userAuthenticated = false
  }

}
