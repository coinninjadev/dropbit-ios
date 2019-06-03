//
//  NetworkManager+NotificationNetworkInteractable.swift
//  DropBit
//
//  Created by BJ Miller on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

extension NetworkManager: NotificationNetworkInteractable {
  func subscribeToTopics(deviceEndpointIds: DeviceEndpointIds, body: NotificationTopicSubscriptionBody) -> Promise<SubscriptionInfoResponse> {
    return cnProvider.request(NotificationTopicSubscriptionTarget.subscribe(deviceEndpointIds, body))
  }

  func getSubscriptionInfo(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionInfoResponse> {
    let deviceEndpointIds = DeviceEndpointIds(response: response)
    return self.getSubscriptionInfo(withDeviceEndpointIds: deviceEndpointIds)
  }

  func getSubscriptionInfo(withDeviceEndpointIds endpointIds: DeviceEndpointIds) -> Promise<SubscriptionInfoResponse> {
    return cnProvider.request(NotificationTopicSubscriptionTarget.getSubscriptions(endpointIds))
  }

  func removeEndpoints(from responses: [DeviceEndpointResponse]) -> Promise<Void> {
    let ids = responses.map { DeviceEndpointIds(response: $0) }
    let promises = ids.map { return cnProvider.requestVoid(DeviceEndpointTarget.delete($0)) }
    return when(fulfilled: promises)
  }

  func unsubscribeFromTopic(topicId: String, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void> {
    return cnProvider.requestVoid(NotificationTopicSubscriptionTarget.unsubscribe(deviceEndpointIds, topicId))
  }
}
