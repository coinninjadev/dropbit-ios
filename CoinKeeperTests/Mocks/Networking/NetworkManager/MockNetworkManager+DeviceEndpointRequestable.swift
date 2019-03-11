//
//  MockNetworkManager+DeviceEndpointRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: DeviceEndpointRequestable {

  func createDeviceEndpoint(forPushToken pushToken: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse> {
    return Promise { _ in }
  }

  func deleteDeviceEndpoint(forIds endpointIds: DeviceEndpointIds) -> Promise<Void> {
    return Promise { _ in }
  }

  func getDeviceEndpoints(serverDeviceId: String) -> Promise<[DeviceEndpointResponse]> {
    return Promise { _ in }
  }

}
