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

  func getGeneralSubscriptions(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<GeneralSubscriptionResponse> {
    return Promise { _ in }
  }

  func subscribeToGeneralTopics(deviceEndpointIds: DeviceEndpointIds, body: GeneralTopicSubscriptionBody) -> Promise<GeneralSubscriptionResponse> {
    return Promise { _ in }
  }
}
