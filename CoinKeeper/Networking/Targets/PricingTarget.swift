//
//  PricingTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum PricingTarget: CoinNinjaTargetType {
  typealias ResponseType = PriceTransactionResponse

  case getTxPricing(String)

}

extension PricingTarget {

  var basePath: String {
    switch self {
    case .getTxPricing: return "pricing"
    }
  }

  var subPath: String? {
    switch self {
    case .getTxPricing(let txid): return txid
    }
  }

  public var method: Moya.Method {
    return .get
  }

  public var task: Task {
    return .requestPlain
  }

}
