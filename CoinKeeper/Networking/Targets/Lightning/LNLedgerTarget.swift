//
//  LNLedgerTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public struct LNLedgerUrlParameters {
  var after: Date?
  var offset: Int
  var limit: Int = 25

  var rfcAfter: String? {
    guard let after = after else { return nil }
    return CKDateFormatter.rfc3339.string(from: after)
  }

  init(after: Date?, page: Int) {
    self.after = after
    self.offset = page * limit
  }
}

public enum LNLedgerTarget: CoinNinjaTargetType {
  typealias ResponseType = LNLedgerResponse

  case get(LNLedgerUrlParameters)

  var basePath: String {
    return "thunderdome"
  }

  var subPath: String? {
    return "ledger"
  }

  public var method: Method {
    return .get
  }

  public var task: Task {
    switch self {
    case .get(let parameters):
      var urlParams: [String: Any] = ["offset": parameters.offset, "limit": parameters.limit]
      if let after = parameters.rfcAfter {
        urlParams["after"] = after
      }

      return .requestParameters(parameters: urlParams, encoding: URLEncoding.default)
    }
  }

}
