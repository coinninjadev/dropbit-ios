//
//  WalletCheckInTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum WalletCheckInTarget: CoinNinjaTargetType {
  typealias ResponseType = CheckInResponse

  case get
  case getNoAuth

}

extension WalletCheckInTarget {

  var basePath: String {
    switch self {
    case .get: return "wallet/check-in"
    case .getNoAuth: return "check-in"
    }
  }

  var subPath: String? {
    return nil
  }

  public var method: Method {
    return .get
  }

  public var task: Task {
    return .requestPlain
  }

  func customNetworkError(for moyaError: MoyaError) -> CKNetworkError? {
    let reachabilityError = CKNetworkError.reachabilityFailed(moyaError)
    guard let statusCode = moyaError.response?.statusCode else {
      return reachabilityError
    }

    switch statusCode {
    case 401: return reachabilityError
    default:  return nil
    }
  }

}
