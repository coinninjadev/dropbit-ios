//
//  CreateDeviceEndpointBody.swift
//  DropBit
//
//  Created by Mitch on 10/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CreateDeviceEndpointBody: Codable {
  let application: DeviceEndpoint.Application
  let platform: DeviceEndpoint.Platform
  let token: String
}
