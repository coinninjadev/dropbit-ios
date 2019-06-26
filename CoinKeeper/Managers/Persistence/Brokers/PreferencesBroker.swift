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

  var selectedCurrency: SelectedCurrency {
    get {
      let stringValue = userDefaultsManager.string(for: .selectedCurrency)
      return stringValue.flatMap { SelectedCurrency(rawValue: $0) } ?? .fiat
    }
    set {
      userDefaultsManager.set(newValue.description, for: .selectedCurrency)
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

}
