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
  func deleteAll() {
  }

  func deleteWallet() {
  }

  func unverifyUser() {
  }

  func removeWalletId() {
  }

  func deleteDeviceEndpointIds() {
  }

  func persist(pendingInvitationData data: PendingInvitationData) {
  }

  func pendingInvitations() -> [PendingInvitationData] {
    return []
  }

  func pendingInvitation(with id: String) -> PendingInvitationData? {
    return nil
  }

  func removePendingInvitation(with id: String) -> PendingInvitationData? {
    return nil
  }

  func setPendingInvitationFailed(_ invitation: PendingInvitationData) {
  }

  func deviceId() -> UUID? {
    return nil
  }

  func setDeviceId(_ uuid: UUID) {
  }

  var receiveAddressIndexGaps: Set<Int> = []
}
