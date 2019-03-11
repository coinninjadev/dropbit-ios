//
//  DeviceEndpointResponse.swift
//  DropBit
//
//  Created by Mitch on 10/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct DeviceEndpointResponse: ResponseDecodable {

  let id: String
  let createdAt: Int
  let updatedAt: Int
  let application: DeviceEndpoint.Application
  let platform: DeviceEndpoint.Platform
  let token: String
  let device: DeviceResponse
  let deviceId: String

  static var sampleJSON: String {
    return """
    {
    "id": "5805b3a0-ed99-4073-ad18-72adff181b9e",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "application": "dropbit-prod-01",
    "platform": "APNS_SANDBOX",
    "token": "740f4707bebcf74f9b7c25d48e3358945f6aa01da5ddb387462c7eaf61bb78ad",
    "device": \(DeviceResponse.sampleJSON),
    "device_id": "158a4cf9-0362-4636-8c68-ed7a98a7f345"
    }
    """
  }

}

extension DeviceEndpointResponse {

  static var requiredStringKeys: [KeyPath<DeviceEndpointResponse, String>] {
    return [\.id, \.token, \.deviceId]
  }

  static var optionalStringKeys: [WritableKeyPath<DeviceEndpointResponse, String?>] { return [] }

}

extension DeviceEndpointResponse: Comparable {
  public static func < (lhs: DeviceEndpointResponse, rhs: DeviceEndpointResponse) -> Bool {
    return lhs.createdAt < rhs.createdAt
  }

  public static func == (lhs: DeviceEndpointResponse, rhs: DeviceEndpointResponse) -> Bool {
    return lhs.id == rhs.id
  }
}
