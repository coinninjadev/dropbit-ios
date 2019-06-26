//
//  NotificationTopicSubscriptionBody.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct NotificationTopicSubscriptionBody: ResponseDecodable, Encodable {
  let topicIds: [String]
}

extension NotificationTopicSubscriptionBody {
  static func emptyInstance() -> NotificationTopicSubscriptionBody {
    return NotificationTopicSubscriptionBody(topicIds: [])
  }

  static var sampleJSON: String {
    return """
    {
    "topic_ids": []
    }
    """
  }

  static var requiredStringKeys: [KeyPath<NotificationTopicSubscriptionBody, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<NotificationTopicSubscriptionBody, String?>] { return [] }

}
