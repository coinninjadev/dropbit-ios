//
//  LNTransactionTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Foundation

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

  static let withdrawMaxInBTC: NSDecimalNumber = -0.00000001

  case pay(LNPayBody)
  case withdraw(LNWithdrawBody)
  case preauth(LNCreatePaymentRequestBody)
  case cancelPreauth(String)

  var basePath: String {
    return thunderdomeBasePath
  }

  var subPath: String? {
    switch self {
    case .pay:        return "pay"
    case .withdraw:   return "withdraw"
    case .preauth:    return "pay/preauth"
    case .cancelPreauth(let id):
      return "pay/preauth/\(id)"
    }
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    return .underlying(moyaError)
  }

  public var method: Moya.Method {
    switch self {
    case .pay,
         .preauth,
         .withdraw:       return .post
    case .cancelPreauth:  return .delete
    }
  }

  public var task: Task {
    switch self {
    case .pay(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .preauth(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .withdraw(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .cancelPreauth:
      return .requestPlain
    }
  }
}
