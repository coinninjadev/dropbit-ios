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

}

extension WalletCheckInTarget {

  var basePath: String {
    return "wallet/check-in"
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

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    if let statusCode = moyaError.response?.statusCode, statusCode == 401 {
      return CKNetworkError.reachabilityFailed(moyaError)
    } else {
      return defaultNetworkError(for: moyaError)
    }
  }

}
