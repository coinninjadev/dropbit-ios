//
//  DeviceEndpointIds.swift
//  DropBit
//
//  Created by BJ Miller on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct DeviceEndpointIds {
  let serverDevice: String
  let endpoint: String
}

extension DeviceEndpointIds {
  init(response: DeviceEndpointResponse) {
    self.init(serverDevice: response.deviceId, endpoint: response.id)
  }
}
