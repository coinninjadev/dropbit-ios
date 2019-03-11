//
//  BlockchainInfoProviderError.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum BlockchainInfoProviderError: Error, LocalizedError {
  case failedTransactionExists(String)

  var errorDescription: String? {
    switch self {
    case .failedTransactionExists(let txid):  return "Failed transaction actually exists on blockchain.info, txid: \(txid)"
    }
  }

}
