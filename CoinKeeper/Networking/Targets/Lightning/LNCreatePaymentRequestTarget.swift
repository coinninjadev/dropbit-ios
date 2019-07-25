//
//  LNCreatePaymentRequestTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public struct LNCreatePaymentRequestBody: Encodable {
  let value: Int
  let expires: Int? //seconds in the future
  let memo: String?

  private enum CodingKeys: String, CodingKey {
    case memo, value, expires
  }

  /// Encode Int keys as String
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(String(value), forKey: .value)
    if let seconds = expires {
      try container.encode(String(seconds), forKey: .expires)
    }
    try container.encode(memo, forKey: .memo)
  }

}

public enum LNCreatePaymentRequestTarget: CoinNinjaTargetType {
  typealias ResponseType = LNCreatePaymentRequestResponse

  case create(LNCreatePaymentRequestBody)

  var basePath: String {
    return ThunderdomeBasePath
  }

  var subPath: String? {
    return "create"
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    return defaultNetworkError(for: moyaError)
  }

  public var method: Method {
    switch self {
    case .create:
      return .post
    }
  }

  public var task: Task {
    switch self {
    case .create(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

}
