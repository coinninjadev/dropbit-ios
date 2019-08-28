//
//  TransactionBroadcastError.swift
//  DropBit
//
//  Created by BJ Miller on 7/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

/// TransactionBroadcastError. Integer values here must match those in error.hpp in CNBitcoinKit.
///
/// - networkUnreachable: The bitcoin network cannot be reached.
/// - broadcastTimedOut: The libbitcoin node trying to be reached did not respond to the tx broadcast.
/// - unknown: General unknown error.
/// - insufficientFee: Transaction fee is insufficient. Libbitcoin nodes maintain a minimum fee that is unknown to us until after a broadcast,
///   and even then, we don't know what the value is.
enum TransactionBroadcastError: Int, Error {
  case networkUnreachable = 8
  case broadcastTimedOut = 13
  case unknown = 43
  case insufficientFee = 70

  init(errorCode: Int) {
    self = TransactionBroadcastError(rawValue: errorCode) ?? .unknown
  }
}
