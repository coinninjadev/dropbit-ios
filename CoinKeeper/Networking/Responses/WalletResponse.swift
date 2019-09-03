//
//  CreateWallet.swift
//  DropBit
//
//  Created by Ben Winters on 5/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CreateWalletBody: Encodable {
  let publicKeyString: String
  let flags: Int
}

public struct WalletResponse: ResponseDecodable {

  let id: String // wallet ID
  let publicKeyString: String // the value provided in the request body
  let flags: Int
  let createdAt: Date
  let updatedAt: Date

  /**
   Is nil if wallet was registered for the first time (typical behavior).
   Is non-nil if a user is already associated with this wallet.
   */
  var userId: String?

}

extension WalletResponse {

  static var requiredStringKeys: [KeyPath<WalletResponse, String>] {
    return [\.id, \.publicKeyString]
  }

  static var optionalStringKeys: [WritableKeyPath<WalletResponse, String?>] {
    return [\.userId]
  }

  static var sampleJSON: String {
    return """
    {
    "id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d",
    "public_key_string": "02262233847a69026f8f3ae027af347f2501adf008fe4f6087d31a1d975fd41473",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "flags": 1,
    "user_id": "ad983e63-526d-4679-a682-c4ab052b20e1"
    }
    """
  }
}
