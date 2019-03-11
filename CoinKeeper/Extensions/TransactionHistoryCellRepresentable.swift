//
//  TransactionHistoryCellRepresentable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TransactionStatus {
  case pending
  case confirmations(Int)
}

protocol TransactionHistoryCellRepresentable {

  /// The counterparty description could be an address, name, phone number, etc.
  var counterparty: String { get }

  /// The status may either be invited/pending or the number of blocks confirming this transaction
  var status: TransactionStatus { get }

  /// True means that the transaction increased the current user's Bitcoin balance
  var isIncoming: Bool { get }

  /// The amount of money received/sent
  var amount: NSDecimalNumber { get }

  /// The symbol corresponding to the currency of the amount
  var currencySymbol: String { get }

  /// The date of the transaction
  var date: Date { get }

  /// An optional string describing the purpose of the transaction
  var memo: String? { get }

}
