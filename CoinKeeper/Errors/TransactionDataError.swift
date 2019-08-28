//
//  TransactionDataError.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

enum TransactionDataError: Error {
  case insufficientFunds
  case insufficientFee

  var localizedDescription: String {
    switch self {
    case .insufficientFunds: return "Insufficient Funds"
    case .insufficientFee: return "Insufficient Fee"
    }
  }

  var messageDescription: String {
    switch self {
    case .insufficientFunds:
      return "Insufficient funds. You can't send more than you have in your wallet. This may be due to unconfirmed transactions."
    case .insufficientFee:
      return "Insufficient fee. Something went wrong calculating a fee for this DropBit invitation, please try again."
    }
  }
}
