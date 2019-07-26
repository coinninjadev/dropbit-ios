//
//  LNTransactionResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

enum LNTransactionDirection: String, Codable {
  case `in` = "IN"
  case out = "OUT"
}

enum LNTransactionStatus: String, Codable {
  case pending = "PENDING"
  case completed = "COMPLETED"
  case expired = "EXPIRED"
  case failed = "FAILED"
}

enum LNTransactionType: String, Codable {
  case btc = "BTC"
  case lightning = "LIGHTNING"
}

struct LNTransactionResult: LNResponseDecodable {

  let id: String
  let accountId: String
  let createdAt: Date
  let expiresAt: Date?
  let status: LNTransactionStatus
  let type: LNTransactionType
  let direction: LNTransactionDirection
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

  static var requiredStringKeys: [KeyPath<LNTransactionResult, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResult, String?>] {
    return []
  }

  enum CodingKeys: String, CodingKey {
    case id, accountId, createdAt, expiresAt, status, type, direction, value, networkFee,
    processingFee, addIndex, request, memo, error
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = "LNAccountResponse"

    id = try container.decode(String.self, forKey: .id)
    accountId = try container.decode(String.self, forKey: .accountId)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    expiresAt = try container.decode(Date.self, forKey: .expiresAt)
    status = try container.decode(LNTransactionStatus.self, forKey: .status)
    type = try container.decode(LNTransactionType.self, forKey: .type)
    direction = try container.decode(LNTransactionDirection.self, forKey: .direction)
    value = try container.decodeStringAsInt(forKey: .value, typeName: typeName)
    networkFee = try container.decodeStringAsInt(forKey: .networkFee, typeName: typeName)
    processingFee = try container.decodeStringAsInt(forKey: .processingFee, typeName: typeName)
    addIndex = try container.decodeStringAsInt(forKey: .addIndex, typeName: typeName)
    request = try container.decode(String.self, forKey: .request)
    memo = try container.decode(String.self, forKey: .memo)
    error = try container.decode(String.self, forKey: .error)
  }

}

struct LNTransactionResponse: LNResponseDecodable {

  var result: LNTransactionResult

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNTransactionResponse, String>] {
    return [\.result.id, \.result.accountId, \.result.request]
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResponse, String?>] {
    return [\.result.memo, \.result.error]
  }

}
