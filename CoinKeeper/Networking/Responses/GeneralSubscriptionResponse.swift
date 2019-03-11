//
//  GeneralSubscriptionResponse.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct GeneralSubscriptionResponse: ResponseDecodable {
  let subscriptions: [SubscriptionResponse]
  let availableTopics: [SubscriptionAvailableTopicResponse]

  static var sampleJSON: String {
    return """
    {
    "subscriptions": [
    \(SubscriptionResponse.sampleJSON)
    ],
    "available_topics": [
    \(SubscriptionAvailableTopicResponse.sampleJSON)
    ]
    }
    """
  }

  static var requiredStringKeys: [KeyPath<GeneralSubscriptionResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<GeneralSubscriptionResponse, String?>] { return [] }
}
