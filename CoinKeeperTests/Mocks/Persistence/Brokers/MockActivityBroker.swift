//
//  MockActivityBroker.swift
//  DropBitUITests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockActivityBroker: CKPersistenceBroker, ActivityBrokerType {

  var isFirstTimeOpeningApp: Bool = false

  func setLastMockLogin(timeInterval: TimeInterval) {
    lastTimeEnteredBackground = timeInterval
  }

  private var lastTimeEnteredBackground: TimeInterval = Date().timeIntervalSince1970
  var wasAskedForLastLoginTime = false
  var lastLoginTime: TimeInterval? {
    wasAskedForLastLoginTime = true
    return lastTimeEnteredBackground
  }

  var setLastLoginTimeWasCalled = false
  func setLastLoginTime() {
    setLastLoginTimeWasCalled = true
    lastTimeEnteredBackground = Date().timeIntervalSince1970
  }

  var firstOpenDate: Date?
  func setFirstOpenDateIfNil(date: Date) { }

  var lastSuccessfulSync: Date?

  var lastPublishedMessageTime: TimeInterval?

  var shownMessageIds: [String] = []

  var unseenTransactionChangesExist: Bool = false

  var lastContactCacheReload: Date?

  var backupWordsReminderShown: Bool = false

}
