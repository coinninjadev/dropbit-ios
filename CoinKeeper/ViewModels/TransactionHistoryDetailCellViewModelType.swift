//
//  TransactionHistoryDetailCellViewModelType.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

/// Defines inputs necessary to determine the values displayed in the cell.
/// Transforms the provided values into formatted strings as needed.
protocol TransactionHistoryDetailCellViewModelType: TransactionHistoryDetailCellDisplayable {
  var isValidTransaction: Bool { get }
  var date: Date? { get }
  var accountType: AccountType { get }
  var isLightningTransfer: Bool { get }
  var amountDetails: TransactionAmountDetails { get }
  var action: TransactionDetailAction? { get }
}

extension TransactionHistoryDetailCellViewModelType {

  var isValidTransaction: Bool { return true }
  var isLightningTransfer: Bool { return false }
  var statusTextColor: UIColor { return .lightGrayText }

  var canAddMemo: Bool {
    if isLightningTransfer { return false }
    return memoConfig == nil
  }

  var statusText: String {
    return status.rawValue
  }

  var displayDate: String? {
    guard let d = date else { return nil }
    return CKDateFormatter.displayFull.string(from: d)
  }

  var amountLabels: TransactionCellAmountLabels {
    return TransactionCellAmountLabels(primaryText: "",
                                  secondaryText: nil,
                                  secondaryAttributedText: nil,
                                  historicalPriceAttributedText: nil)
  }

  var actionButtonConfig: DetailCellActionButtonConfig? {
    return nil
  }

}

enum TransactionDirection: String {
  case `in`, out
}

enum AccountType {
  case bitcoin, lightning
}

enum TransactionStatus: String {
  case pending
  case broadcasting
  case completed
  case canceled
  case expired
}

struct TransactionAmountDetails {
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let primaryBTCAmount: NSDecimalNumber
  let fiatWhenCreated: NSDecimalNumber?
  let fiatWhenTransacted: NSDecimalNumber?
}
