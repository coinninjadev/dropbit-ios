//
//  DropBitMeTarget.swift
//  DropBit
//
//  Created by Ben Winters on 4/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum UserPublicURLTarget: CoinNinjaTargetType {
  typealias ResponseType = UserPublicURLResponse

  case get
  case update(UserPublicURLBody)

}

extension UserPublicURLTarget {

  var basePath: String {
    return "user"
  }

  var subPath: String? {
    return "publicURL"
  }

  public var method: Method {
    switch self {
    case .get:     return .get
    case .update:  return .patch
    }
  }

  public var task: Task {
    switch self {
    case .get:
      return .requestPlain
    case .update(let response):
      return .requestCustomJSONEncodable(response, encoder: self.customEncoder)
    }
  }

}
