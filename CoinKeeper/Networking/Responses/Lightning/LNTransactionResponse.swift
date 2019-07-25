//
//  LNTransactionResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

struct LNTransactionResponse: ResponseDecodable {

  let id: String
  let accountId: String
  let createdAt: Date
  let updatedAt: Date
  let expiresAt: Date
  let status: String
  let type: String
  let direction: String
  let value: Int
  let networkFee: Int
  let processingFee: Int
  let addIndex: Int
  let request: String
  var memo: String?
  var error: String?

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNTransactionResponse, String>] {
    return [\.id, \.accountId, \.status, \.type, \.direction, \.request]
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResponse, String?>] {
    return [\.memo, \.error]
  }

}
