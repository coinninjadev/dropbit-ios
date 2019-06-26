//
//  NotificationTopicSubscriptionBody.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct NotificationTopicSubscriptionBody: Encodable {
  let topicIds: [String]
}

extension NotificationTopicSubscriptionBody {
  static func emptyInstance() -> NotificationTopicSubscriptionBody {
    return NotificationTopicSubscriptionBody(topicIds: [])
  }
}
