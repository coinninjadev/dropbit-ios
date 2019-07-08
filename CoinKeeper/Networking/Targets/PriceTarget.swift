//
//  PriceTarget.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum PricePeriod {
  case daily
  case monthly
  case allTime

  var urlString: String {
    switch(self) {
    case .daily: return "daily"
    case .monthly: return "monthly"
    case .allTime: return "alltime"
    }
  }
}

public enum PriceTarget: CoinNinjaTargetType {
  typealias ResponseType = PriceSummaryResponse

  case price(PricePeriod)
}

extension PriceTarget {

  var basePath: String {
    return "pricing/historic"
  }

  var subPath: String? {
    return nil
  }

  public var method: Method {
    return .get
  }

  public var task: Task {
    switch self {
    case .price(let period):
      return .requestParameters(parameters: ["period": period.urlString], encoding: URLEncoding.default)
    }
  }

  public var headers: [String: String]? {
    switch self {
    default: return nil
    }
  }

}
