//
//  MockNetworkManager+DeviceRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: DeviceRequestable {

  func createDevice(for uuid: UUID) -> Promise<DeviceResponse> {
    return Promise { _ in }
  }

  func getDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse> {
    return Promise { _ in }
  }
}
