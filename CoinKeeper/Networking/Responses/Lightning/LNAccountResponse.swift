//
//  LNAccountResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

struct LNAccountResponse: LNResponseDecodable {

  let id: String
  let createdAt: Date
  let updatedAt: Date
  let address: String
  let balance: Int
  let pendingIn: Int
  let pendingOut: Int

  static var sampleJSON: String {
    return """
    {
    "address" : "2N2AcBSDxE551LeZVNdSPRkMNwLDjvyhpVX",
    "id" : "pubkey:0288d7cacd3a24847e3caee75ce96832e144a2b436223ab3df96427b635be3a138",
    "created_at" : "2019-07-25T18:26:52.833391Z",
    "updated_at" : "2019-07-25T18:26:52.833391Z",
    "pending_out" : "0",
    "balance" : "215000000000",
    "pending_in" : "4000"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<LNAccountResponse, String>] {
    return [\.id, \.address]
  }

  static var optionalStringKeys: [WritableKeyPath<LNAccountResponse, String?>] {
    return []
  }

  private enum CodingKeys: String, CodingKey {
    case id, createdAt, updatedAt, address, balance, pendingIn, pendingOut
  }

  /// Decode Int keys from String
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    address = try container.decode(String.self, forKey: .address)

    let typeName = "LNAccountResponse"
    balance = try container.decodeStringAsInt(forKey: .balance, typeName: typeName)
    pendingIn = try container.decodeStringAsInt(forKey: .pendingIn, typeName: typeName)
    pendingOut = try container.decodeStringAsInt(forKey: .pendingOut, typeName: typeName)
  }

}
