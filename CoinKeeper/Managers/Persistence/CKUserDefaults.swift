//
//  CKUserDefaults.swift
//  DropBit
//
//  Created by Ben Winters on 3/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CKUserDefaults: PersistenceUserDefaultsType {

  let standardDefaults = UserDefaults.standard

  enum Value: String {
    case optIn
    case optOut

    var defaultsString: String { return self.rawValue }
  }

  enum Key: String, CaseIterable {
    case invitationPopup
    case firstTimeOpeningApp
    case exchangeRateBTCUSD
    case feeBest
    case feeBetter
    case feeGood
    case blockheight
    case walletID // for background fetching purposes
    case userID   // for background fetching purposes
    case uuid // deviceID
    case shownMessageIds
    case lastPublishedMessageTimeInterval
    case coinNinjaServerDeviceId
    case receiveAddressIndexGaps
    case deviceEndpointId
    case devicePushToken
    case unseenTransactionChangesExist
    case backupWordsReminderShown
    case migrationVersions //database
    case keychainMigrationVersions
    case contactCacheMigrationVersions
    case lastSuccessfulSyncCompletedAt
    case dustProtectionEnabled
    case selectedCurrency
    case lastContactCacheReload
    case dontShowShareTransaction
    case yearlyPriceHighNotificationEnabled
    case lastTimeEnteredBackground

    var defaultsString: String { return self.rawValue }
  }

  /// Use this method to not delete everything from UserDefaults
  func deleteWallet() {
    removeValues(forKeys: [
      .exchangeRateBTCUSD,
      .feeBest,
      .feeBetter,
      .feeGood,
      .blockheight,
      .receiveAddressIndexGaps,
      .walletID,
      .userID,
      .backupWordsReminderShown,
      .unseenTransactionChangesExist,
      .lastSuccessfulSyncCompletedAt,
      .yearlyPriceHighNotificationEnabled
      ])
  }

  func deleteAll() {
    removeValues(forKeys: Key.allCases)
  }

  func unverifyUser() {
    removeValues(forKeys: [.userID])
  }

}
