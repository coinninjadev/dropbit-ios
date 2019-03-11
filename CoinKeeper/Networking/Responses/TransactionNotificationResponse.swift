//
//  TransactionNotificationResponse.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct TransactionNotificationResponse: ResponseCodable {
  let txid: String
  let address: String
  var encryptedPayload: String?
  var encryptedFormat: String?
}

extension TransactionNotificationResponse {

  static var sampleJSON: String {
    return """
    {
      "txid": "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
      "address": "34Xa8X8pfwvUyq4VGZFXUhzrTemJrbgcsu",
      "encrypted_payload": "Y2QyM2M4ZjY4MTU4ZjhiYmRjZDMzN2E1ZjI0NTE2MjBkNmY3ZjNhMjc5MGQ1OTg1M2ZkYzYyMGI4NzZkNGUwMzgxNThmOGJiZGNkNzIzM2ViN2EzM2IK",
      "encrypted_format": "1"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<TransactionNotificationResponse, String>] {
    return [\.txid, \.address]
  }

  static var optionalStringKeys: [WritableKeyPath<TransactionNotificationResponse, String?>] {
    return [\.encryptedPayload, \.encryptedFormat]
  }

}

extension TransactionNotificationResponse: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(txid)
    hasher.combine(address)
  }

  static func == (lhs: TransactionNotificationResponse, rhs: TransactionNotificationResponse) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
