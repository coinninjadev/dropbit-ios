//
//  NetworkManager+SubscribeToWalletRequestable.swift
//  DropBit
//
//  Created by BJ Miller on 10/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol SubscribeToWalletRequestable: AnyObject {
  func getWalletSubscriptions() -> Promise<[SubscriptionResponse]>
  func subscribeToWalletTopic(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse>
}

extension NetworkManager: SubscribeToWalletRequestable {

  func getWalletSubscriptions() -> Promise<[SubscriptionResponse]> {
    return cnProvider.requestList(SubscribeToWalletTarget.getSubscriptions)
  }

  func subscribeToWalletTopic(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse> {
    let body = SubscribeToWalletBody(deviceEndpointId: response.id)
    return cnProvider.request(SubscribeToWalletTarget.subscribe(body))
  }

}
