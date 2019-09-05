//
//  WalletTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum WalletTarget: CoinNinjaTargetType {
  typealias ResponseType = WalletResponse

  case create(CreateWalletBody)
  case update(CreateWalletBody)
  case get
  case reset
  case subscribe(SubscribeToWalletBody)
}

extension WalletTarget {

  var basePath: String {
    return "wallet"
  }

  var subPath: String? {
    switch self {
    case .reset:                    return "reset"
    case .subscribe:                return "subscribe"
    case .create, .update, .get:    return nil
    }
  }

  public var method: Moya.Method {
    switch self {
    case .create, .update, .subscribe:  return .post
    case .get:                          return .get
    case .reset:                        return .put
    }
  }

  public var task: Task {
    switch self {
    case .get,
         .reset:                return .requestPlain
    case .create(let body):     return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .update(let body):     return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .subscribe(let body):  return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    if let statusCode = moyaError.unacceptableStatusCode,
      statusCode == 401,
      case .get = self,
      moyaError.responseDescription.containsAny(messagesToUnverify) {

      return .shouldUnverify(moyaError, .wallet)

    } else {
      return defaultNetworkError(for: moyaError)
    }
  }

}
