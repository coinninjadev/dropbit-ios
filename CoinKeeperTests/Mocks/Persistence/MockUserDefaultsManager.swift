//
//  MockUserDefaultsManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockUserDefaultsManager: PersistenceUserDefaultsType {

  func deleteAll() {}
  func deleteWallet() {}
  func unverifyUser() {}
  func removeWalletId() {}
  func deleteDeviceEndpointIds() {}
  func persist(pendingInvitationData data: PendingInvitationData) {}
  func setPendingInvitationFailed(_ invitation: PendingInvitationData) {}
  func setDeviceId(_ uuid: UUID) {}

  func deviceId() -> UUID? {
    return UUID()
  }

  func removePendingInvitation(with id: String) -> PendingInvitationData? {
    return nil
  }

  func pendingInvitation(with id: String) -> PendingInvitationData? {
    return nil
  }

  func pendingInvitations() -> [PendingInvitationData] {
    return []
  }

  var receiveAddressIndexGapsValue: Set<Int> = []
  var receiveAddressIndexGaps: Set<Int> {
    get {
      return receiveAddressIndexGapsValue
    }
    set {
      receiveAddressIndexGapsValue = newValue
    }
  }

  func dustProtectionIsEnabled() -> Bool {
    return false
  }

  func dustProtectionMinimumAmount() -> Int {
    return 0
  }

  var dontShowShareTransaction: Bool = false

  // standardDefaults is not used by MockPersistenceManager, and is not accessed outside PersistenceManager (wjf, 2018-04)
  var standardDefaults = UserDefaults(suiteName: "com.coinninja.unittests")
  var value: [String: Any] = [:]

}
