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
  case get(String) //txid or ledgerEntryId
  case query(ElasticRequest)

}

extension TransactionNotificationTarget {

  var basePath: String {
    return "transaction/notification"
  }

  var subPath: String? {
    switch self {
    case .create:         return nil
    case .get(let txid):  return txid
    case .query:          return "query"
    }
  }

  public var method: Method {
    switch self {
    case .create,
         .query:  return .post
    case .get:    return .get
    }
  }

  public var task: Task {
    switch self {
    case .create(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .query(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .get:
      return .requestPlain
    }
  }

}
