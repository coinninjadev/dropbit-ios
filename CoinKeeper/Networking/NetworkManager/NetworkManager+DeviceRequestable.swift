//
//  NetworkManager+DeviceRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol DeviceRequestable: AnyObject {
  func createDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
  func getDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
}

extension NetworkManager: DeviceRequestable {

  func createDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse> {
    let body = CreateDeviceBody(application: .dropBit, platform: .ios, uuid: localDeviceId)
    return cnProvider.request(DevicesTarget.create(body))
  }

  func getDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse> {
    return cnProvider.request(DevicesTarget.get(localDeviceId))
  }
}
