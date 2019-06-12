//
//  SubscriptionResponse.swift
//  DropBit
//
//  Created by BJ Miller on 10/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SubscriptionType: String {
  case wallet = "Wallet"
  case general = "General"
  case topic = "Topic"
}

struct SubscriptionResponse: ResponseDecodable {

  let id: String
  let createdAt: Int
  let updatedAt: Int
  let ownerType: String
  let ownerId: String // the topic id matched from available topics response
  let deviceEndpoint: DeviceEndpointResponse
  let deviceEndpointId: String

  var ownerTypeCase: SubscriptionType {
    return SubscriptionType(rawValue: ownerType) ?? .general
  }

}

extension SubscriptionResponse {
  static var sampleJSON: String {
    return """
    {
    "id": "752c6358-d746-4d26-90ec-9f5f2d72d438",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "owner_type": "Wallet",
    "owner_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d",
    "device_endpoint": \(DeviceEndpointResponse.sampleJSON),
    "device_endpoint_id": "5805b3a0-ed99-4073-ad18-72adff181b9e"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<SubscriptionResponse, String>] {
    return [\.id, \.ownerType, \.deviceEndpointId]
  }

  static var optionalStringKeys: [WritableKeyPath<SubscriptionResponse, String?>] { return [] }

}
