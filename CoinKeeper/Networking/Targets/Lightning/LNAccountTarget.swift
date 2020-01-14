//
//  LNAccountTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum LNAccountTarget: CoinNinjaTargetType {
  typealias ResponseType = LNAccountResponse

  case get

  var basePath: String {
    return thunderdomeBasePath
  }

  var subPath: String? {
    return "account"
  }

  public var method: Method {
    switch self {
    case .get:  return .get
    }
  }

  public var task: Task {
    switch self {
    case .get:
      return .requestPlain
    }
  }
}
