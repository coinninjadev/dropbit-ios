//
//  NetworkManager+DeviceEndpointRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol DeviceEndpointRequestable: AnyObject {
  func deleteDeviceEndpoint(forIds endpointIds: DeviceEndpointIds) -> Promise<Void>
  func createDeviceEndpoint(forPushToken pushToken: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse>
  func getDeviceEndpoints(serverDeviceId: String) -> Promise<[DeviceEndpointResponse]>
}

extension NetworkManager: DeviceEndpointRequestable {

  func createDeviceEndpoint(forPushToken pushToken: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse> {
    var platform = DeviceEndpoint.Platform.apns
    var application = DeviceEndpoint.Application.dropbit
    #if PUSHDEBUGENVIRONMENT
    platform = .sandbox
    application = .dropBitTest
    #elseif PUSHBETAENVIRONMENT
    application = .dropBitTest
    #endif

    let body = CreateDeviceEndpointBody(application: application, platform: platform, token: pushToken)
    return cnProvider.request(DeviceEndpointTarget.create(serverDeviceId, body))
  }

  func getDeviceEndpoints(serverDeviceId: String) -> Promise<[DeviceEndpointResponse]> {
    return cnProvider.requestList(DeviceEndpointTarget.getEndpoints(serverDeviceId))
  }

  func deleteDeviceEndpoint(forIds endpointIds: DeviceEndpointIds) -> Promise<Void> {
    return cnProvider.requestVoid(DeviceEndpointTarget.delete(endpointIds))
  }

}
