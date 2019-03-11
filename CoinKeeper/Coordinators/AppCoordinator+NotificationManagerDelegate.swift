//
//  AppCoordinator+NotificationManagerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import os.log
import CNBitcoinKit
import PromiseKit
import CoreData

extension AppCoordinator: NotificationManagerDelegate {
  func manager(_ manager: NotificationManagerType, didActUponInvitationResponseNotificationWithID id: String) {
    pushTransactionHistory()
  }

  func localDeviceId(_ manager: NotificationManagerType) -> String {
    return persistenceManager.findOrCreateDeviceId().uuidString.lowercased()
  }

  func persistServerDeviceId(_ serverDeviceId: String) {
    persistenceManager.set(serverDeviceId, for: .coinNinjaServerDeviceId)
  }

  func persistDeviceEndpointId(_ deviceEndpointId: String) {
    persistenceManager.set(deviceEndpointId, for: .deviceEndpointId)
  }

  func deleteDeviceEndpointIds() {
    persistenceManager.deleteDeviceEndpointIds()
  }
}
