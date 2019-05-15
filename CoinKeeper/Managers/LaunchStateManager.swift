//
//  LaunchStateManager.swift
//  CoinKeeper
//
// Created by BJ Miller on 2/26/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import os.log

protocol LaunchStateManagerType: AnyObject {
  var shouldRequireAuthentication: Bool { get }
  var launchType: LaunchType { get set }
  var skippedVerification: Bool { get }
  var userAuthenticated: Bool { get }
  init(persistenceManager: PersistenceManagerType)
  func currentProperties() -> LaunchStateProperties
  func profileIsActivated() -> Bool
  func deviceIsVerified() -> Bool
  func walletExists() -> Bool
  func walletIsBackedUp() -> Bool
  func shouldRegisterWallet() -> Bool
  func userWasAuthenticated()
  func unauthenticateUser()
  func isFirstTime() -> Bool
  func isFirstTimeAfteriCloudRestore() -> Bool
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
}

class LaunchStateManager: LaunchStateManagerType {

  private let persistenceManager: PersistenceManagerType
  var launchType: LaunchType = .userInitiated
  var selectedSetupFlow: SetupFlow?

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

    if persistenceManager.walletWords() != nil {
      options.insert(.walletExists)
    }

    if let value = persistenceManager.keychainManager.retrieveValue(for: .walletWordsBackedUp) as? NSNumber,
      value.boolValue == true {
      options.insert(.wordsBackedUp)
    }

    let bgContext = persistenceManager.databaseManager.createBackgroundContext()
    bgContext.performAndWait {
      if persistenceManager.userVerificationStatus(in: bgContext) == .verified {
        options.insert(.deviceVerified)
      }
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
    let walletIdExists = persistenceManager.walletId(in: bgContext) != nil

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "launch_state_manager")
    os_log("Wallet exists: %d, wallet ID exists: %d", log: logger, type: .debug, walletExists, walletIdExists)
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
    return properties == .deviceVerified
  }

  func deviceIsVerified() -> Bool {
    return currentProperties().contains(.deviceVerified)
  }

  func profileIsActivated() -> Bool {
    let criteria: LaunchStateProperties = [.wordsBackedUp, .deviceVerified]
    let properties = currentProperties()

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "launch_state_manager")
    let wordsBackedUp = properties.contains(.wordsBackedUp)
    let deviceVerified = properties.contains(.deviceVerified)
    os_log("Words backed up: %d, Device verified: %d", log: logger, type: .debug, wordsBackedUp, deviceVerified)

    return criteria.isSubset(of: properties)
  }

  // MARK: In-Memory Status

  /// PIN/Face/Touch ID verification
  private(set) var userAuthenticated: Bool = false

  var shouldRequireAuthentication: Bool {
    guard !isFirstTime() else { return false }
    return !userAuthenticated && launchType == .userInitiated
  }

  func userWasAuthenticated() {
    persistenceManager.setLastLoginTime()
    userAuthenticated = true
  }

  func unauthenticateUser() {
    userAuthenticated = false
  }

}
