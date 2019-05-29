//
//  SubscriptionAvailableTopicResponse.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SubscriptionTopicType: String {
  case general
  case btcHigh = "btc_high"
}

struct SubscriptionAvailableTopicResponse: ResponseDecodable {
  let id: String
  let createdAt: Int
  let updatedAt: Int
  let name: String
  let displayName: String
  let description: String

  static var sampleJSON: String {
    return """
    {
    "id": "5805b3a0-ed99-4073-ad18-72adff181b9e",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "name": "Max 256 chars",
    "display_name": "Max 10 chars, required for SMS",
    "description": "Use me in the UI"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<SubscriptionAvailableTopicResponse, String>] {
    return [\.id, \.name, \.displayName, \.description]
  }

  static var optionalStringKeys: [WritableKeyPath<SubscriptionAvailableTopicResponse, String?>] { return [] }
}

extension SubscriptionAvailableTopicResponse {
  var type: SubscriptionTopicType {
    return SubscriptionTopicType(rawValue: name) ?? .general
  }
}
