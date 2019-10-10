//
//  LNCreatePaymentRequestTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

enum LNCreatePaymentRequestTargetError: UserNotifiableError {
  case amountTooHigh
}

public struct LNCreatePaymentRequestBody: Encodable {
  let value: Int
  let expires: Int? //seconds in the future
  let memo: String?
}

public enum LNCreatePaymentRequestTarget: CoinNinjaTargetType {
  typealias ResponseType = LNCreatePaymentRequestResponse

  case create(LNCreatePaymentRequestBody)

  var basePath: String {
    return thunderdomeBasePath
  }

  var subPath: String? {
    return "create"
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    switch moyaError.response?.statusCode {
    case 400:
      return .invoiceAmountTooHigh
    default:
      return defaultNetworkError(for: moyaError)
    }
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
