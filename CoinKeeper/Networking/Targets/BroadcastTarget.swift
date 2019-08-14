//
//  BroadcastTarget.swift
//  DropBit
//
//  Created by Ben Winters on 8/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum BroadcastTarget: CoinNinjaTargetType {
  typealias ResponseType = StringResponse

  case sendRawTransaction(String)
}

extension BroadcastTarget {

  var basePath: String {
    return "broadcast"
  }

  var subPath: String? {
    return nil
  }

  public var method: Method {
    return .post
  }

  public var task: Task {
    switch self {
    case .sendRawTransaction(let encodedTx):
      let body = encodedTx.data(using: .utf8) ?? Data()
      return .requestData(body)
    }
  }

}
