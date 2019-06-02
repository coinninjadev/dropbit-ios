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
      let shouldSubscribe = persistenceManager.yearlyPriceHighNotificationIsEnabled()
      return shouldSubscribe
    }
  }

  func unsubscribeFromTopicsIfNeeded(
    with response: SubscriptionInfoResponse,
    deviceEndpointIds: DeviceEndpointIds) -> Promise<SubscriptionInfoResponse> {
    let activeSubscriptions = response.subscriptions
    let toUnsubscribe = activeSubscriptions.first { (innerResponse) -> Bool in
      let maybeTopicResponse = response.availableTopics.first(where: { $0.id == innerResponse.ownerId })
      guard let topicResponse = maybeTopicResponse else { return false }
      switch topicResponse.type {
      case .btcHigh:
        let shouldUnsubscribe = self.shouldUnsubscribeFromTopic(topicResponse, subscribedTopics: activeSubscriptions)
        return shouldUnsubscribe
      case .general:
        return false
      }
    }
    if let toUnsubscribe = toUnsubscribe {
      return networkManager.unsubscribeToTopics(deviceEndpointIds: deviceEndpointIds, topicId: toUnsubscribe.ownerId)
        .then { _ in return Promise.value(response) }
    } else {
      return Promise.value(response)
    }
  }

  func shouldUnsubscribeFromTopic(_ topic: SubscriptionAvailableTopicResponse, subscribedTopics: [SubscriptionResponse]) -> Bool {
    guard let type = SubscriptionTopicType(rawValue: topic.name) else { return false }
    switch type {
    case .general: return false
    case .btcHigh:
      let isSubscribed = subscribedTopics.contains(where: { subResponse -> Bool in subResponse.ownerId == topic.id })
      let isSettingDisabled = !persistenceManager.yearlyPriceHighNotificationIsEnabled()
      let shouldUnsubscribe = isSettingDisabled && isSubscribed
      return shouldUnsubscribe
    }
  }
}
