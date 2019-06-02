//
//  MockNetworkManager+NotificationNetworkInteractable.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit

extension MockNetworkManager: NotificationNetworkInteractable {
  func subscribeToTopics(deviceEndpointIds: DeviceEndpointIds, body: NotificationTopicSubscriptionBody) -> Promise<SubscriptionInfoResponse> {
    return Promise { _ in }
  }

  func getWalletSubscriptions() -> Promise<[SubscriptionResponse]> {
    return Promise { _ in }
  }

  func createDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse> {
    return Promise { _ in }
  }

  func subscribeToWalletTopic(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse> {
    return Promise { _ in }
  }

  func removeEndpoints(from responses: [DeviceEndpointResponse]) -> Promise<Void> {
    return Promise { _ in }
  }

  func getSubscriptionInfo(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionInfoResponse> {
    return Promise { _ in }
  }

  func unsubscribeToTopics(deviceEndpointIds: DeviceEndpointIds, topicId: String) -> Promise<Void> {
    return Promise { _ in }
  }
}
