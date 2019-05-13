//
//  UserIdentityTarget.swift
//  DropBit
//
//  Created by BJ Miller on 5/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum UserIdentityTarget: CoinNinjaTargetType {
  typealias ResponseType = UserIdentityResponse

  case add(UserIdentityBody)
}

extension UserIdentityTarget {
  var basePath: String {
    return "user"
  }

  var subPath: String? {
    return "identity"
  }

  public var method: Method {
    return .post
  }

  public var task: Task {
    switch self {
    case .add(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }
}
