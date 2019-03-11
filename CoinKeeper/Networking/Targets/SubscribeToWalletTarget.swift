//
//  SubscribeToWalletTarget.swift
//  DropBit
//
//  Created by BJ Miller on 10/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum SubscribeToWalletTarget: CoinNinjaTargetType {
  typealias ResponseType = SubscriptionResponse

  case subscribe(SubscribeToWalletBody)
  case getSubscriptions

}

extension SubscribeToWalletTarget {

  var basePath: String {
    return "wallet"
  }

  var subPath: String? {
    switch self {
    case .subscribe:        return "subscribe"
    case .getSubscriptions: return "subscriptions"
    }
  }

  public var method: Method {
    switch self {
    case .subscribe:        return .post
    case .getSubscriptions: return .get
    }
  }

  public var validationType: ValidationType {
    switch self {
    case .subscribe: return .customCodes([201])
    case .getSubscriptions: return .customCodes([200])
    }
  }

  public var task: Task {
    switch self {
    case .subscribe(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .getSubscriptions:
      return .requestPlain
    }
  }

}
