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

  func shouldSubscribeToTopic(withName name: String) -> Bool {
    guard let type = SubscriptionTopicType(rawValue: name) else { return false }
    switch type {
    case .general: return true
    case .btcHigh:
      let shouldShowYearlyHigh = persistenceManager.yearlyPriceHighNotificationIsEnabled()
      return shouldShowYearlyHigh
    }
  }
}
