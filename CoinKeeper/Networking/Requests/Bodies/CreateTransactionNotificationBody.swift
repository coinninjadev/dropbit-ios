//
//  CreateTransactionNotificationBody.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CreateTransactionNotificationBody: Encodable {

  /// For lightning, this should be the ledger entry `id`
  let txid: String

  /// For lightning, this should be the encoded invoice
  let address: String

  let identityHash: String
  let encryptedPayload: String
  let encryptedFormat: String
}
