//
//  TransactionDetailPopoverDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionDetailPopoverDisplayable {
  var directionConfig: TransactionCellDirectionConfig { get }
  var detailStatusText: String { get }
  var breakdownItems: [TransactionPopoverBreakdownItem] { get }
  var txid: String { get }
  var txidURL: URL? { get }
}

protocol TransactionDetailPopoverViewModelType: TransactionDetailPopoverDisplayable, TransactionDetailCellViewModelType {
  var direction: TransactionDirection { get }
  var isLightningTransfer: Bool { get }
  var paymentIdIsValid: Bool { get }
  var walletTxType: WalletTransactionType { get }
  var onChainConfirmations: Int? { get }
}

extension TransactionDetailPopoverViewModelType {

  var txidURL: URL? {
    guard paymentIdIsValid else { return nil }
    return CoinNinjaUrlFactory.buildUrl(for: .transaction(id: txid))
  }

  var breakdownAmounts: [BreakdownAmount] {
    //TODO: compose this based on the transaction type and the available TransactionAmounts in SummaryCellViewModelType
    //    whenSentAmountLabel.text = viewModel.breakdownSentAmountText
    //    networkFeeAmountLabel.text = viewModel.breakdownFeeAmountText
    //    confirmationsAmountLabel.text = viewModel.confirmationsText

    return []
  }

  var breakdownItems: [TransactionPopoverBreakdownItem] {
    var results = breakdownAmounts.map { TransactionPopoverBreakdownItem(amount: $0) }

    //TODO: include confirmations conditionally
    if let count = onChainConfirmations {
      results.append(TransactionPopoverBreakdownItem(confirmations: count) )
    }
    return results
  }

}

struct BreakdownAmount {
  let type: BreakdownItemType
  let amounts: ConvertedAmounts
}

struct TransactionPopoverBreakdownItem {
  let title: String
  let detail: String

  init(amount: BreakdownAmount) {
    self.title = amount.type.title
    self.detail = "" //TODO: format the amounts
  }

  init(confirmations: Int) {
    self.title = "Confirmations"
    self.detail = confirmations >= 6 ? "6+" : String(describing: confirmations)
  }
}

enum BreakdownItemType {
  case amount
  case totalSent
  case networkFees
  case dropbitFees
  case transferred
  case whenSent

  var title: String {
    switch self {
    case .amount:           return "Amount"
    case .totalSent:        return "Total Sent"
    case .whenSent:         return "When Sent"
    case .networkFees:      return "Network Fees"
    case .dropbitFees:      return "DropBit Fees"
    case .transferred:      return "Transferred"
    }
  }
}
