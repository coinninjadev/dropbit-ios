//
//  CreateTransactionNotificationBody.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CreateTransactionNotificationBody: Encodable {
  let txid: String
  let address: String
  let identityHash: String
  let encryptedPayload: String
  let encryptedFormat: String
}
