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

  case update(UserPublicURLBody)

}

extension UserPublicURLTarget {

  var basePath: String {
    return "user"
  }

  var subPath: String? {
    return "public_url"
  }

  public var method: Method {
    switch self {
    case .update:  return .patch
    }
  }

  public var task: Task {
    switch self {
    case .update(let response):
      return .requestCustomJSONEncodable(response, encoder: self.customEncoder)
    }
  }

}
