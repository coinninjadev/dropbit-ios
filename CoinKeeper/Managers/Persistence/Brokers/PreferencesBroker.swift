//
//  PreferencesBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class PreferencesBroker: CKPersistenceBroker, PreferencesBrokerType {

  private let standardDustProtectionThreshold: Int = 1_000

  override init(keychainManager: PersistenceKeychainType,
                databaseManager: PersistenceDatabaseType,
                userDefaultsManager: PersistenceUserDefaultsType) {
    super.init(keychainManager: keychainManager,
               databaseManager: databaseManager,
               userDefaultsManager: userDefaultsManager)

    if userDefaultsManager.object(for: .yearlyPriceHighNotificationEnabled) == nil {
      userDefaultsManager.set(true, for: .yearlyPriceHighNotificationEnabled)
    }
  }

  var dustProtectionMinimumAmount: Int {
    return dustProtectionIsEnabled ? standardDustProtectionThreshold : 0
  }

  var dustProtectionIsEnabled: Bool {
    get { return userDefaultsManager.bool(for: .dustProtectionEnabled) }
    set { userDefaultsManager.set(newValue, for: .dustProtectionEnabled) }
  }

  var yearlyPriceHighNotificationIsEnabled: Bool {
    get {
      if userDefaultsManager.object(for: .yearlyPriceHighNotificationEnabled) == nil {
        userDefaultsManager.set(true, for: .yearlyPriceHighNotificationEnabled) // allow notification by default
      }
      return userDefaultsManager.bool(for: .yearlyPriceHighNotificationEnabled)
    }
    set {
      userDefaultsManager.set(newValue, for: .yearlyPriceHighNotificationEnabled)
    }
  }

  var selectedWalletTransactionType: WalletTransactionType {
    get {
      let stringValue = userDefaultsManager.string(for: .selectedWalletTransactionType)
      return stringValue.flatMap { WalletTransactionType(rawValue: $0) } ?? .onChain
    }
    set {
      userDefaultsManager.set(newValue.rawValue, for: .selectedWalletTransactionType)
    }
  }

  var selectedCurrency: SelectedCurrency {
    get {
      let stringValue = userDefaultsManager.string(for: .selectedCurrency)
      return stringValue.flatMap { SelectedCurrency(rawValue: $0) } ?? .fiat
    }
    set {
      userDefaultsManager.set(newValue.description, for: .selectedCurrency)
    }
  }

  var lightningWalletLockedStatus: LockStatus {
    get {
      let stringValue = userDefaultsManager.string(for: .lightningWalletLockedStatus)
      return stringValue.flatMap { LockStatus(rawValue: $0) } ?? .locked
    }
    set {
      userDefaultsManager.set(newValue.rawValue, for: .lightningWalletLockedStatus)
    }
  }

  var dontShowShareTransaction: Bool {
    get { return userDefaultsManager.bool(for: .dontShowShareTransaction) }
    set { userDefaultsManager.set(newValue, for: .dontShowShareTransaction) }
  }

  var didOptOutOfInvitationPopup: Bool {
    get {
      let popupString = self.userDefaultsManager.string(for: .invitationPopup) ?? ""
      if let value = CKUserDefaults.Value(rawValue: popupString), case .optOut = value {
        return true
      } else {
        return false
      }
    }
    set {
      let val: CKUserDefaults.Value = newValue ? .optOut : .optIn
      userDefaultsManager.set(val, for: .invitationPopup)
    }
  }

  var adjustableFeesIsEnabled: Bool {
    get { return userDefaultsManager.bool(for: .adjustableFeesEnabled) }
    set { userDefaultsManager.set(newValue, for: .adjustableFeesEnabled) }
  }

  var preferredTransactionFeeType: TransactionFeeType {
    get {
      let rawValue = userDefaultsManager.integer(for: .preferredTransactionFeeMode)
      return TransactionFeeType.mode(for: rawValue)
    }
    set {
      userDefaultsManager.set(newValue.rawValue, for: .preferredTransactionFeeMode)
    }
  }

  var dontShowLightningRefill: Bool {
    get { return userDefaultsManager.bool(for: .dontShowLightningRefill) }
    set { userDefaultsManager.set(newValue, for: .dontShowLightningRefill) }
  }

  var reviewLastRequestDate: Date? {
    get { return self.userDefaultsManager.date(for: .reviewLastRequestDate) }
    set { userDefaultsManager.set(newValue, for: .reviewLastRequestDate) }
  }

  var reviewLastRequestVersion: String? {
    get { return userDefaultsManager.string(for: .reviewLastRequestVersion) }
    set { userDefaultsManager.set(newValue, for: .reviewLastRequestVersion) }
  }

  var firstLaunchDate: Date {
    get {
      if userDefaultsManager.date(for: .firstLaunchDate) == nil {
        userDefaultsManager.set(Date(), for: .firstLaunchDate)
      }
      return userDefaultsManager.date(for: .firstLaunchDate) ?? Date()
    }
    set { userDefaultsManager.set(newValue, for: .firstLaunchDate) }
  }
}
