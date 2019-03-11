//
//  CreateDeviceBody.swift
//  DropBit
//
//  Created by Mitch on 10/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CreateDeviceBody: Codable {
  let application: DeviceApplication
  let platform: DevicePlatform
  let uuid: String
}
