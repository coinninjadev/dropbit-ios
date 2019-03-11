//
//  UserQueryTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum UserQueryTarget: CoinNinjaTargetType {
  typealias ResponseType = StringDictResponse

  case query([String])

}

extension UserQueryTarget {

  var basePath: String {
    return "user/query"
  }

  var subPath: String? {
    return nil
  }

  public var method: Method {
    return .post
  }

  public var task: Task {
    switch self {
    case .query(let numberHashes):
      guard let data = queryBody(for: "phone_number_hash", value: numberHashes) else { return .requestPlain }
      return .requestCompositeData(bodyData: data, urlParameters: ["page": 1, "perPage": numberHashes.count])
    }
  }

}
