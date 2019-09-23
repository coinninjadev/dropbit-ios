//
//  LNAccountResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

struct LNAccountResponse: ResponseDecodable {

  let id: String
  let createdAt: Date
  let updatedAt: Date?
  var address: String?
  let balance: Int
  let pendingIn: Int
  let pendingOut: Int
  let locked: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case address
    case balance
    case pendingIn = "pending_in"
    case pendingOut = "pending_out"
    case locked
  }

  init(from decoder: Decoder) throws {
    let formatter = CKDateFormatter.rfc3339Decoding
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)

    let createdAt = try container.decode(String.self, forKey: .createdAt)
    if let date = formatter.date(from: createdAt) {
      self.createdAt = date
    } else {
      throw DecodingError.keyNotFound(CodingKeys.createdAt,
                                      DecodingError.Context(codingPath: [CodingKeys.createdAt],
                                                            debugDescription: "Date does not conform to rfc3339Decoding spec"))
    }

    if let updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt),
      let date = formatter.date(from: updatedAt) {
      self.updatedAt = date
    } else {
      self.updatedAt = nil
    }

    self.address = try container.decodeIfPresent(String.self, forKey: .address)
    self.balance = try container.decode(Int.self, forKey: .balance)
    self.pendingIn = try container.decode(Int.self, forKey: .pendingIn)
    self.pendingOut = try container.decode(Int.self, forKey: .pendingOut)
    self.locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
  }

  static var decoder: JSONDecoder {
    return JSONDecoder()
  }

  static var sampleJSON: String {
    return """
    {
    "address" : "2N2AcBSDxE551LeZVNdSPRkMNwLDjvyhpVX",
    "id" : "pubkey:0288d7cacd3a24847e3caee75ce96832e144a2b436223ab3df96427b635be3a138",
    "created_at" : "2019-07-25T18:26:52.833391Z",
    "updated_at" : "2019-07-25T18:26:52.833391Z",
    "pending_out" : "0",
    "balance" : "215000000000",
    "pending_in" : "4000",
    "locked" : true
    }
    """
  }

  static var requiredStringKeys: [KeyPath<LNAccountResponse, String>] {
    return [\.id]
  }

  static var optionalStringKeys: [WritableKeyPath<LNAccountResponse, String?>] {
    return [\.address]
  }
}
