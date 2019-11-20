//
//  MerchantTarget.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum MerchantTarget: CoinNinjaTargetType {
  typealias ResponseType = MerchantConfigurationResponse

  case fetch
}

extension MerchantTarget {

  var basePath: String {
    return "config"
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

  public var headers: [String: String]? {
    return nil
  }

}
