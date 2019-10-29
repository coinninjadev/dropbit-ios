//
//  CoinNinjaBroadcastTarget.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

enum CoinNinjaBroadcastTarget: CoinNinjaTargetType {

  typealias ResponseType = CoinNinjaBroadcastResponse

  case broadcast(String)
}

extension CoinNinjaBroadcastTarget {

  var basePath: String {
    return "broadcast"
  }

  var subPath: String? {
    return nil
  }

  var method: Method {
    return .post
  }

  var task: Task {
    switch self {
    case .broadcast(let tx):
      let data = queryBody(encodedTx: tx) ?? Data()
      return .requestCompositeData(bodyData: data, urlParameters: [:])
    }

  }

  private func queryBody(encodedTx: String) -> Data? {
    let body = CoinNinjaBroadcastTransactionBody(encodedTx: encodedTx)
    let data = try? customEncoder.encode(body)
    return data
  }
}

struct CoinNinjaBroadcastTransactionBody: Encodable {
  var encodedTx: String

  init(encodedTx: String) {
    self.encodedTx = encodedTx
  }
}

