//
//  AddressesTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum AddressesTarget: CoinNinjaTargetType {
  typealias ResponseType = AddressTransactionSummaryResponse

  /// multiAddress params - addresses: [String], pageNumber: Int, perPage: Int
  case query([String], Int, Int)

}

extension AddressesTarget {

  var basePath: String {
    return "addresses"
  }

  var subPath: String? {
    switch self {
    case .query:            return "query"
    }
  }

  public var method: Method {
    switch self {
    case .query:  return .post
    }
  }

  public var task: Task {
    switch self {
    case .query(let addresses, let page, let perPage):
      guard let data = queryBody(for: "address", value: addresses) else { return .requestPlain }
      return .requestCompositeData(bodyData: data, urlParameters: ["page": page, "perPage": perPage])
    }
  }

  public var validationType: ValidationType {
    return .customCodes([200, 404])
  }

}
