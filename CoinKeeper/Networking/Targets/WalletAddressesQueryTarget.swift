//
//  WalletAddressesQueryTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

enum WalletAddressesQueryTarget: CoinNinjaTargetType {
  typealias ResponseType = WalletAddressesQueryResponse

  case query(ElasticRequest)

}

extension WalletAddressesQueryTarget {

  var basePath: String {
    return "wallet/addresses"
  }

  var subPath: String? {
    return "query"
  }

  var method: Method {
    return .post
  }

  var task: Task {
    switch self {
    case .query(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

}
