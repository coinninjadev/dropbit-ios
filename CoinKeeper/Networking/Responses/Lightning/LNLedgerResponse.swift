//
//  LNLedgerResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct LNLedgerResponse: LNResponseDecodable {

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
