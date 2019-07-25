//
//  LNDecodePaymentRequestTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public struct LNDecodePaymentRequestBody: Encodable {
  let request: String
}

enum LNDecodePaymentRequestTarget: CoinNinjaTargetType {
  typealias ResponseType = LNDecodePaymentRequestResponse

  case decode(LNDecodePaymentRequestBody)

  var basePath: String {
    return "thunderdome"
  }

  var subPath: String? {
    return "decode"
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    return defaultNetworkError(for: moyaError)
  }

  public var method: Method {
    return .post
  }

  public var task: Task {
    switch self {
    case .decode(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

}
