//
//  LNTransactionTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public struct LNPayBody: Encodable {
  let request: String
  let value: Int
}

public struct LNWithdrawBody: Encodable {
  let address: String
  let value: Int
  let blocks: Int
  var estimate: Bool
}

public enum LNTransactionTarget: CoinNinjaTargetType {
  typealias ResponseType = LNTransactionResponse

  case pay(LNPayBody)
  case withdraw(LNWithdrawBody)

  var basePath: String {
    return thunderdomeBasePath
  }

  var subPath: String? {
    switch self {
    case .pay:      return "pay"
    case .withdraw: return "withdraw"
    }
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    return defaultNetworkError(for: moyaError)
  }

  public var method: Method {
    switch self {
    case .pay:      return .post
    case .withdraw: return .post
    }
  }

  public var task: Task {
    switch self {
    case .pay(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .withdraw(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }
}
