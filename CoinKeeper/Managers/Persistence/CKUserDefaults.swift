//
//  CKUserDefaults.swift
//  DropBit
//
//  Created by Ben Winters on 3/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CKUserDefaults: PersistenceUserDefaultsType {

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
    case didTutorial
    case walletID // for background fetching purposes
    case userID   // for background fetching purposes
    case pendingInvitations  // [String: [String: Data]]
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
    case lastSuccessfulSyncCompletedAt

    var defaultsString: String { return self.rawValue }
  }

  private func removeValue(forKey key: Key) {
    CKUserDefaults.standardDefaults.set(nil, forKey: key.defaultsString)
  }

  private func removeValues(forKeys keys: [Key]) {
    keys.forEach { removeValue(forKey: $0) }
  }

  func deviceId() -> UUID? {
    guard let deviceIdString = CKUserDefaults.standardDefaults.string(forKey: Key.uuid.defaultsString) else { return nil }
    return UUID(uuidString: deviceIdString)
  }

  func setDeviceId(_ uuid: UUID) {
    CKUserDefaults.standardDefaults.set(uuid.uuidString, forKey: Key.uuid.defaultsString)
  }

  func deleteDeviceEndpointIds() {
    removeValues(forKeys: [
      .deviceEndpointId,
      .coinNinjaServerDeviceId
      ])
  }

  /// Use this method to not delete everything from UserDefaults
  func deleteWallet() {
    removeValues(forKeys: [
      .exchangeRateBTCUSD,
      .feeBest,
      .feeBetter,
      .feeGood,
      .didTutorial,
      .blockheight,
      .receiveAddressIndexGaps,
      .walletID,
      .unseenTransactionChangesExist,
      .userID,
      .pendingInvitations,
      .backupWordsReminderShown,
      .unseenTransactionChangesExist,
      .lastSuccessfulSyncCompletedAt
      ])
    CKUserDefaults.standardDefaults.synchronize()
  }

  func deleteAll() {
    removeValues(forKeys: Key.allCases)
  }

  func removeWalletId() {
    removeValue(forKey: .walletID)
  }

  func unverifyUser() {
    removeValues(forKeys: [.pendingInvitations, .userID])
  }

  let indexGapKey = CKUserDefaults.Key.receiveAddressIndexGaps.rawValue
  var receiveAddressIndexGaps: Set<Int> {
    get {
      if let gaps = CKUserDefaults.standardDefaults.array(forKey: indexGapKey) as? [Int] {
        return Set(gaps)
      } else {
        return Set<Int>()
      }
    }
    set {
      let numbers: [NSNumber] = Array(newValue).map { NSNumber(value: $0) } // map Set<Int> to [NSNumber]
      CKUserDefaults.standardDefaults.set(NSArray(array: numbers), forKey: indexGapKey)
    }
  }

  func persist(pendingInvitationData invitationData: PendingInvitationData) {
    guard let data = invitationData.asData() else { return }
    let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
    var existing: [String: Data] = [:]
    if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
      existing = value
    }
    let toMerge: [String: Data] = [invitationData.id: data]
    let merged = existing.merging(toMerge, uniquingKeysWith: { (_, new) in new })
    CKUserDefaults.standardDefaults.set(merged, forKey: pendingKey)
  }

  func pendingInvitations() -> [PendingInvitationData] {
    let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
    guard let pendingInvitations = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] else { return [] }
    return pendingInvitations.values.compactMap { PendingInvitationData.decode(from: $0) }
  }

  func pendingInvitation(with id: String) -> PendingInvitationData? {
    let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
    guard let pendingInvitations = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] else { return nil }
    return pendingInvitations[id].flatMap { PendingInvitationData.decode(from: $0) }
  }

  @discardableResult
  func removePendingInvitation(with id: String) -> PendingInvitationData? {
    let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
    var existing: [String: Data] = [:]
    if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
      existing = value
    }
    let removed = existing.removeValue(forKey: id).flatMap { PendingInvitationData.decode(from: $0) }
    CKUserDefaults.standardDefaults.set(existing, forKey: pendingKey)
    return removed
  }

  func setPendingInvitationFailed(_ invitation: PendingInvitationData) {
    var newInvitation = invitation
    newInvitation.failedToSendAt = Date()
    guard let data = newInvitation.asData() else { return }

    let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
    var existing: [String: Data] = [:]
    if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
      existing = value
    }

    existing[invitation.id] = data

    CKUserDefaults.standardDefaults.set(existing, forKey: pendingKey)
  }
}
