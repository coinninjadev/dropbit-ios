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
  func subscribeToGeneralTopics(deviceEndpointIds: DeviceEndpointIds, body: GeneralTopicSubscriptionBody) -> Promise<GeneralSubscriptionResponse> {
    return cnProvider.request(GeneralSubscriptionTarget.subscribe(deviceEndpointIds, body))
  }

  func getGeneralSubscriptions(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<GeneralSubscriptionResponse> {
    let deviceEndpointIds = DeviceEndpointIds(response: response)
    return cnProvider.request(GeneralSubscriptionTarget.getSubscriptions(deviceEndpointIds))
  }

  func removeEndpoints(from responses: [DeviceEndpointResponse]) -> Promise<Void> {
    let ids = responses.map { DeviceEndpointIds(response: $0) }
    let promises = ids.map { return cnProvider.requestVoid(DeviceEndpointTarget.delete($0)) }
    return when(fulfilled: promises)
  }
}
