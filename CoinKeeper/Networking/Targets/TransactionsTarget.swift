//
//  TransactionsTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum TransactionsTarget: CoinNinjaTargetType {
  typealias ResponseType = TransactionResponse

  case get(String)
  case query([String])
}

extension TransactionsTarget {

  var basePath: String {
    return "transactions"
  }

  var subPath: String? {
    switch self {
    case .get(let txid):  return txid
    case .query:          return "query"
    }
  }

  public var method: Method {
    switch self {
    case .get:    return .get
    case .query:  return .post
    }
  }

  public var task: Task {
    switch self {
    case .get:
      return .requestPlain
    case .query(let txids):
      guard let data = queryBody(for: "txid", value: txids) else { return .requestPlain }
      return .requestCompositeData(bodyData: data, urlParameters: [:])
    }
  }

}
