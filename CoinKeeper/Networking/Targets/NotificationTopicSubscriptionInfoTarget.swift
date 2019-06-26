//
//  NotificationTopicSubscriptionInfoTarget.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum NotificationTopicSubscriptionInfoTarget: CoinNinjaTargetType {
  typealias ResponseType = SubscriptionInfoResponse

  case getSubscriptions(DeviceEndpointIds)
  case subscribe(DeviceEndpointIds, NotificationTopicSubscriptionBody)
  case unsubscribe(DeviceEndpointIds, String) // String is the topicId
}

extension NotificationTopicSubscriptionInfoTarget {
  var basePath: String {
    return "devices"
  }

  var subPath: String? {
    switch self {
    case .getSubscriptions(let ids),
         .subscribe(let ids, _):
      return "\(ids.serverDevice)/endpoints/\(ids.endpoint)/subscriptions"
    case .unsubscribe(let ids, let topicId):
      return "\(ids.serverDevice)/endpoints/\(ids.endpoint)/subscriptions/\(topicId)"
    }
  }

  public var method: Method {
    switch self {
    case .getSubscriptions: return .get
    case .subscribe:        return .post
    case .unsubscribe:      return .delete
    }
  }

  public var validationType: ValidationType {
    switch self {
    case .getSubscriptions: return .customCodes([200])
    case .subscribe:        return .customCodes([201, 500]) // 500 is acceptable due to test envs
    case .unsubscribe:      return .customCodes([204])
    }
  }

  public var task: Task {
    switch self {
    case .getSubscriptions, .unsubscribe:
      return .requestPlain
    case .subscribe(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }
}
