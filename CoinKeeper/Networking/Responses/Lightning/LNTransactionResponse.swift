//
//  LNTransactionResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Foundation

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
  var accountId: String?
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

  /// For results where type is .btc, the id is the txid followed by a colon
  /// and the index of the vout that funded the lightning load address.
  /// Note that the first component may be "preauth" for sent invitations.
  var cleanedId: String {
    if let firstComponent = id.components(separatedBy: ":").first,
      firstComponent != LNTransactionResult.preauthPrefix {
      return firstComponent
    } else {
      return id
    }
  }

  var isPreauth: Bool {
    return cleanedId.starts(with: LNTransactionResult.preauthPrefix)
  }

  static let preauthPrefix = "preauth"

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNTransactionResult, String>] {
    return [] // Nested objects are not directly validated, refer to parent object
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResult, String?>] {
    return [] // Nested objects are not directly validated, refer to parent object
  }

}

struct LNTransactionResponse: LNResponseDecodable {

  var result: LNTransactionResult

  static var sampleJSON: String {
    let requestString = """
    lnbcrt20u1pwn7pv9pp5q34wtxrz4cldmadzlp3kp80t0djsw7287v3q2d5vm8d0vws9khmsdz523jhxapqwfjh
    zat9wd6zqem9dejhyct5v4jzqct58gsryvp38yknqdedxgujqvf58g6rzw3s8yszkvpsxqcqcqzpgaaz0g60w829jhz0djzn67v6
    u6wey65nx9yempjwgw50kzp4u36kszjlargswtrsla8xvcx9pecjjmyrgerttn5kjfv84zqunx2kx3jgp668svu
    """.removingMultilineLineBreaks(replaceBreaksWithSpaces: false)

    return """
    {
    "result" : {
    "id" : "046ae59862ae3eddf5a2f863609deb7b65077947f32205368cd9daf63a05b5f7:int",
    "processing_fee" : "0",
    "created_at" : "2019-07-29T14:41:13.740538Z",
    "expires_at" : "2019-07-29T15:41:09Z",
    "network_fee" : "0",
    "memo" : "Test request generated at: 2019-07-29 14:41:09 +0000",
    "type" : "lightning",
    "value" : "2002",
    "error" : "",
    "updated_at" : "2019-07-29T14:41:13.740538Z",
    "request" : "\(requestString)",
    "account_id" : "pubkey:0288d7cacd3a24847e3caee75ce96832e144a2b436223ab3df96427b635be3a138",
    "status" : "pending",
    "direction" : "out"
    }
    }
    """
  }

  static var requiredStringKeys: [KeyPath<LNTransactionResponse, String>] {
    return [\.result.id]
  }

  static var optionalStringKeys: [WritableKeyPath<LNTransactionResponse, String?>] {
    return [\.result.memo, \.result.error, \.result.request, \.result.accountId]
  }

}
