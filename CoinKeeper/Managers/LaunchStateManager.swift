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
  var nextLaunchStep: UserProfileLaunchStep { get }
  var userAuthenticated: Bool { get }
  init(persistenceManager: PersistenceManagerType)
  func profileIsActivated() -> Bool
  func deviceIsVerified() -> Bool
  func walletExists() -> Bool
  func walletIsBackedUp() -> Bool
  func shouldRegisterWallet() -> Bool
  func userWasAuthenticated()
  func unauthenticateUser()
  func isFirstTime() -> Bool
}

/**
 Uses OptionSet to allow users to complete these steps in any order and at any time.
 Each option represents a boolean condition.
 */
struct UserProfileOptionSet: OptionSet {
  let rawValue: Int

  static let pinEntered = UserProfileOptionSet(rawValue: 1 << 0)
  static let walletExists = UserProfileOptionSet(rawValue: 1 << 1)
  static let wordsBackedUp = UserProfileOptionSet(rawValue: 1 << 2)
  static let deviceVerified = UserProfileOptionSet(rawValue: 1 << 3)
}

enum UserProfileLaunchStep: Int {
  case enterPin
  case createWallet //covers both persisting words and checking that the user backed them up
  case verifyDevice //covers both registering the wallet and verifying the phone number
  case enterApp
}

class LaunchStateManager: LaunchStateManagerType {
  private let persistenceManager: PersistenceManagerType
  var launchType: LaunchType = .userInitiated

  required init(persistenceManager: PersistenceManagerType) {
    self.persistenceManager = persistenceManager
  }

  func walletIsBackedUp() -> Bool {
    return retrieveProfileOptions().contains(.wordsBackedUp)
  }

  private func retrieveProfileOptions() -> UserProfileOptionSet {
    var options: UserProfileOptionSet = []

    if persistenceManager.keychainManager.retrieveValue(for: .userPin) != nil {
      options.insert(.pinEntered)
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
    return retrieveProfileOptions().contains(.walletExists)
  }

  /**
   The wallet may still exist in the keychain from a previous installation,
   while the wallet ID is not persisted across installations.
   */
  func shouldRegisterWallet() -> Bool {
    let walletExists = retrieveProfileOptions().contains(.walletExists)

    let bgContext = persistenceManager.createBackgroundContext()
    let walletIdExists = persistenceManager.walletId(in: bgContext) != nil

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "launch_state_manager")
    os_log("Wallet exists: %d, wallet ID exists: %d", log: logger, type: .debug, walletExists, walletIdExists)
    return walletExists && !walletIdExists
  }

  /**
   This is intended for the initial setup process and determining the next step.
   This is not intended for identifying skipped steps once they are in the app.
   That requires looking at the underlying option set in profileOptions.

   Note that backing up the words is a skippable part of the createWallet step,
   so it is a separate option, but not a separate step.
   */
  var nextLaunchStep: UserProfileLaunchStep {
    let options = retrieveProfileOptions()
    // Option set checks ordered in reverse of steps
    if options.contains([.pinEntered, .walletExists, .deviceVerified]) {
      return .enterApp

    } else if options.contains([.pinEntered, .walletExists]) {
      return skippedVerification ? .enterApp : .verifyDevice

    } else if options.contains([.pinEntered]) {
      return .createWallet

    } else {
      return .enterPin
    }
  }

  func isFirstTime() -> Bool {
    return retrieveProfileOptions().isEmpty
  }

  func deviceIsVerified() -> Bool {
    return retrieveProfileOptions().contains(.deviceVerified)
  }

  func profileIsActivated() -> Bool {
    let criteria: UserProfileOptionSet = [.wordsBackedUp, .deviceVerified]
    let options = retrieveProfileOptions()

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "launch_state_manager")
    let wordsBackedUp = options.contains(.wordsBackedUp)
    let deviceVerified = options.contains(.deviceVerified)
    os_log("Words backed up: %d, Device verified: %d", log: logger, type: .debug, wordsBackedUp, deviceVerified)

    return criteria.isSubset(of: options)
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
