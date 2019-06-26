//
//  NotificationTopicSubscriptionTarget.swift
//  DropBit
//
//  Created by BJ Miller on 6/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum NotificationTopicSubscriptionTarget: CoinNinjaTargetType {
  typealias ResponseType = NotificationTopicSubscriptionBody

  case subscribe(DeviceEndpointIds, NotificationTopicSubscriptionBody)
}

extension NotificationTopicSubscriptionTarget {
  var basePath: String {
    return "devices"
  }

  var subPath: String? {
    switch self {
    case .subscribe(let ids, _):
      return "\(ids.serverDevice)/endpoints/\(ids.endpoint)/subscriptions"
    }
  }

  public var method: Method {
    switch self {
    case .subscribe: return .post
    }
  }

  public var validationType: ValidationType {
    switch self {
    case .subscribe: return .customCodes([201, 500]) // 500 is acceptable due to test envs
    }
  }

  public var task: Task {
    switch self {
    case .subscribe(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }
}
