//
//  AppCoordinator+NotificationManagerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import PromiseKit
import CoreData

extension AppCoordinator: NotificationManagerDelegate {
  func localDeviceId(_ manager: NotificationManagerType) -> String {
    return persistenceManager.brokers.device.findOrCreateDeviceId().uuidString.lowercased()
  }

  func persistServerDeviceId(_ serverDeviceId: String) {
    persistenceManager.brokers.device.serverDeviceId = serverDeviceId
  }

  func persistDeviceEndpointId(_ deviceEndpointId: String) {
    persistenceManager.brokers.device.deviceEndpointId = deviceEndpointId
  }

  func deleteDeviceEndpointIds() {
    persistenceManager.brokers.device.deleteDeviceEndpointIds()
  }

  /// used to determine if topic should even be considered for subscription
  func shouldSubscribeToTopic(withName name: String) -> Bool {
    guard let type = SubscriptionTopicType(rawValue: name) else { return false }
    switch type {
    case .general: return true
    case .btcHigh:
      return persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled
    }
  }

  func pushToken() -> String? {
    return persistenceManager.brokers.device.pushToken
  }

  func unsubscribeFromTopic(type: SubscriptionTopicType, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void> {
    // 1. search subscribed topics for type
    return networkManager.getSubscriptionInfo(withDeviceEndpointIds: deviceEndpointIds)
      .then { (subscriptionInfoResponse: SubscriptionInfoResponse) -> Promise<Void> in
        let subscriptions = subscriptionInfoResponse.subscriptions
        let availableTopics = subscriptionInfoResponse.availableTopics
        let maybeTopic = availableTopics.first(where: { $0.type == type })
        // 2. get topic to unsubscribe from, if any, and ask if should unsubscribe
        if let topic = maybeTopic, self.shouldUnsubscribeFromTopic(topic, subscribedTopics: subscriptions) {
          // 3. if should, unsubscribe
          return self.networkManager.unsubscribeFromTopic(topicId: topic.id, deviceEndpointIds: deviceEndpointIds)
        } else {
          return Promise.value(())
        }
    }
  }

  func subscribeToTopic(type: SubscriptionTopicType, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void> {
    // 1. search subscribed topics for type
    return self.networkManager.getSubscriptionInfo(withDeviceEndpointIds: deviceEndpointIds)
      .then { (subInfoResponse: SubscriptionInfoResponse) -> Promise<Void> in
        let subscriptions = subInfoResponse.subscriptions
        let availableTopics = subInfoResponse.availableTopics
        let maybeTopic = availableTopics.first(where: { $0.type == type })
        // 2. get topic to unsubscribe from, if any, and ask if should unsubscribe
        if let topic = maybeTopic, self.shouldSubscribeToTopic(topic, subscribedTopics: subscriptions) {
          // 3. if should, subscribe
          let body = NotificationTopicSubscriptionBody(topicIds: [topic.id])
          return self.networkManager
            .subscribeToTopics(deviceEndpointIds: deviceEndpointIds, body: body)
            .asVoid()
        } else {
          return Promise.value(())
        }
      }
  }

  func updateNotificationEnabled(_ enabled: Bool, forType type: SubscriptionTopicType) {
    switch type {
    case .btcHigh: persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled = enabled
    case .general: break
    }
  }

  private func shouldUnsubscribeFromTopic(_ topic: SubscriptionAvailableTopicResponse, subscribedTopics: [SubscriptionResponse]) -> Bool {
    let type = topic.type
    switch type {
    case .general: return false
    case .btcHigh:
      let isSubscribed = subscribedTopics.contains(where: { $0.ownerId == topic.id })
      let isSettingDisabled = !persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled
      let shouldUnsubscribe = isSettingDisabled && isSubscribed
      return shouldUnsubscribe
    }
  }

  /// used locally in this file, cross-comparing existing subscriptions, to determine if subscription is needed`
  private func shouldSubscribeToTopic(_ topic: SubscriptionAvailableTopicResponse, subscribedTopics: [SubscriptionResponse]) -> Bool {
    let type = topic.type
    switch type {
    case .general: return true
    case .btcHigh:
      let isSubscribed = subscribedTopics.contains(where: { $0.ownerId == topic.id })
      let isSettingEnabled = persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled
      let shouldSubscribe = isSettingEnabled && !isSubscribed
      return shouldSubscribe
    }
  }
}
