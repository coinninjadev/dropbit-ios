//
//  TransactionNotificationTarget.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum TransactionNotificationTarget: CoinNinjaTargetType {
  typealias ResponseType = TransactionNotificationResponse

  case create(CreateTransactionNotificationBody)
  case get(String) //txid

}

extension TransactionNotificationTarget {

  var basePath: String {
    return "transaction/notification"
  }

  var subPath: String? {
    switch self {
    case .create:         return nil
    case .get(let txid):  return txid
    }
  }

  public var method: Method {
    switch self {
    case .create: return .post
    case .get:    return .get
    }
  }

  public var task: Task {
    switch self {
    case .create(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .get:
      return .requestPlain
    }
  }

}
