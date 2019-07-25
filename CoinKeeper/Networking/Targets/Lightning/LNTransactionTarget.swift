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

  private enum CodingKeys: String, CodingKey {
    case request, value
  }

  /// Encode Int keys as String
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(request, forKey: .request)
    try container.encode(String(value), forKey: .value)
  }
}

public struct LNWithdrawBody: Encodable {
  let address: String
  let value: Int
  let blocks: Int

  private enum CodingKeys: String, CodingKey {
    case address, value, blocks
  }

  /// Encode Int keys as String
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(address, forKey: .address)
    try container.encode(String(value), forKey: .value)
    try container.encode(String(blocks), forKey: .blocks)
  }

}

public enum LNTransactionTarget: CoinNinjaTargetType {
  typealias ResponseType = LNTransactionResponse

  case pay(LNPayBody)
  case withdraw(LNWithdrawBody)

  var basePath: String {
    return ThunderdomeBasePath
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
