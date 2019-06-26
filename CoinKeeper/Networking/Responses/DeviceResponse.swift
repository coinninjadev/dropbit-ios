//
//  DeviceResponse.swift
//  DropBit
//
//  Created by Mitch on 10/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum DevicePlatform: String, Codable {
  case ios
  case all
}

enum DeviceApplication: String, Codable {
  case dropBit = "DropBit"
}

public struct DeviceResponse: ResponseDecodable, Encodable {

  let id: String
  let createdAt: Int
  let updatedAt: Int
  let application: String
  let platform: String
  let uuid: String

  var applicationCase: DeviceApplication {
    return DeviceApplication(rawValue: self.application) ?? .dropBit
  }

  var platformCase: DevicePlatform {
    return DevicePlatform(rawValue: self.platform) ?? .ios
  }
}

extension DeviceResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "158a4cf9-0362-4636-8c68-ed7a98a7f345",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "application": "dropbit-prod-01",
    "platform": "ios",
    "uuid": "998207d6-5b1e-47c9-84e9-895f52a1b455"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<DeviceResponse, String>] {
    return [\.id, \.application, \.platform, \.uuid]
  }

  static var optionalStringKeys: [WritableKeyPath<DeviceResponse, String?>] { return [] }

}
