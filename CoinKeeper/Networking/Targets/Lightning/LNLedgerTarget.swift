//
//  LNLedgerTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

struct LNLedgerResponse: ResponseDecodable {

  let ledger: [LNTransactionResult]

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNLedgerResponse, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<LNLedgerResponse, String?>] {
    return []
  }

}

public enum LNLedgerTarget: CoinNinjaTargetType {
  typealias ResponseType = LNLedgerResponse

  case get

  var basePath: String {
    return "ledger"
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

}
