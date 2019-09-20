//
//  ActivityBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class ActivityBroker: CKPersistenceBroker, ActivityBrokerType {

  /// Initial value will return false, so getter and setter reverse value
  var isFirstTimeOpeningApp: Bool {
    get { return !userDefaultsManager.bool(for: .firstTimeOpeningApp) }
    set { userDefaultsManager.set(!newValue, for: .firstTimeOpeningApp) }
  }

  var firstOpenDate: Date? {
    return userDefaultsManager.date(for: .firstOpenDate)
  }

  func setFirstOpenDateIfNil(date: Date) {
    guard firstOpenDate == nil else { return }
    userDefaultsManager.set(date, for: .firstOpenDate)
  }

  func setLastLoginTime() {
    userDefaultsManager.set(Date().timeIntervalSince1970, for: .lastTimeEnteredBackground)
  }

  var lastLoginTime: TimeInterval? {
    return userDefaultsManager.double(for: .lastTimeEnteredBackground)
  }

  var lastSuccessfulSync: Date? {
    get { return userDefaultsManager.date(for: .lastSuccessfulSyncCompletedAt) }
    set { userDefaultsManager.set(newValue, for: .lastSuccessfulSyncCompletedAt) }
  }

  var lastPublishedMessageTime: TimeInterval? {
    get { return userDefaultsManager.double(for: .lastPublishedMessageTimeInterval) }
    set { userDefaultsManager.set(newValue, for: .lastPublishedMessageTimeInterval) }
  }

  var shownMessageIds: [String] {
    get { return userDefaultsManager.array(for: .shownMessageIds) as? [String] ?? [] }
    set { userDefaultsManager.set(newValue, for: .shownMessageIds) }
  }

  var unseenTransactionChangesExist: Bool {
    get { return userDefaultsManager.bool(for: .unseenTransactionChangesExist) }
    set { userDefaultsManager.set(newValue, for: .unseenTransactionChangesExist) }
  }

  var lastContactCacheReload: Date? {
    get { return userDefaultsManager.date(for: .lastContactCacheReload) }
    set { userDefaultsManager.set(newValue, for: .lastContactCacheReload) }
  }

  var backupWordsReminderShown: Bool {
    get { return userDefaultsManager.bool(for: .backupWordsReminderShown) }
    set { userDefaultsManager.set(newValue, for: .backupWordsReminderShown) }
  }

}
