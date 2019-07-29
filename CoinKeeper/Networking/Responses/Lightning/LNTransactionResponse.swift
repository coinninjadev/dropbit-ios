//
//  LNTransactionResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

enum LNTransactionStatus: String, Codable {
  case pending, completed, expired, failed
}

enum LNTransactionType: String, Codable {
  case btc, lightning
}

enum LNTransactionDirection: String, Codable {
  case `in`, out
}

struct LNTransactionResult: LNResponseDecodable {

  let id: String
  let accountId: String
  let createdAt: Date
  let updatedAt: Date?
  let expiresAt: Date?
  let status: LNTransactionStatus
  let type: LNTransactionType
  let direction: LNTransactionDirection
  let value: Int
  let networkFee: Int
  let processingFee: Int
  var request: String?
  var memo: String?
  var error: String?

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNTransactionResult, String>] {
    return [] // Nested objects are not directly validated, refer to parent object
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResult, String?>] {
    return [] // Nested objects are not directly validated, refer to parent object
  }

  enum CodingKeys: String, CodingKey {
    case id, accountId, createdAt, updatedAt, expiresAt, status, type, direction, value, networkFee,
    processingFee, request, memo, error
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = "LNAccountResponse"

    id = try container.decode(String.self, forKey: .id)
    accountId = try container.decode(String.self, forKey: .accountId)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    status = try container.decode(LNTransactionStatus.self, forKey: .status)
    type = try container.decode(LNTransactionType.self, forKey: .type)
    direction = try container.decode(LNTransactionDirection.self, forKey: .direction)
    value = try container.decodeStringAsInt(forKey: .value, typeName: typeName)
    networkFee = try container.decodeStringAsInt(forKey: .networkFee, typeName: typeName)
    processingFee = try container.decodeStringAsInt(forKey: .processingFee, typeName: typeName)
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
    return [\.result.id, \.result.accountId]
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResponse, String?>] {
    return [\.result.memo, \.result.error, \.result.request]
  }

}
