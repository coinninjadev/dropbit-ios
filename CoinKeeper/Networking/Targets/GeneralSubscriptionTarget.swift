//
//  GeneralSubscriptionTarget.swift
//  DropBit
//
//  Created by BJ Miller on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum GeneralSubscriptionTarget: CoinNinjaTargetType {
  typealias ResponseType = GeneralSubscriptionResponse

  case getSubscriptions(DeviceEndpointIds)
  case subscribe(DeviceEndpointIds, GeneralTopicSubscriptionBody)
}

extension GeneralSubscriptionTarget {
  var basePath: String {
    return "devices"
  }

  var subPath: String? {
    switch self {
    case .getSubscriptions(let ids), .subscribe(let ids, _):
      return "\(ids.serverDevice)/endpoints/\(ids.endpoint)/subscriptions"
    }
  }

  public var method: Method {
    switch self {
    case .getSubscriptions: return .get
    case .subscribe:        return .post
    }
  }

  public var validationType: ValidationType {
    switch self {
    case .getSubscriptions: return .customCodes([200])
    case .subscribe:        return .customCodes([201])
    }
  }

  public var task: Task {
    switch self {
    case .getSubscriptions:
      return .requestPlain
    case .subscribe(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }
}
