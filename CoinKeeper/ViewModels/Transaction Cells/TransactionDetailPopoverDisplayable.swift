//
//  TransactionDetailPopoverDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionDetailPopoverDisplayable {
  var directionConfig: TransactionCellAvatarConfig { get }
  var detailStatusText: String { get }
  var breakdownItems: [TransactionBreakdownItem] { get }
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
    if let transferType = lightningTransferType {
      switch transferType {
      case .deposit:
        return [totalSentBreakdown, onChainNetworkFeesBreakdown].compactMap { $0 }
      case .withdraw:
        return [totalWithdrawalBreakdown, onChainNetworkFeesBreakdown,
                dropBitFeesBreakdown, netWithdrawalBreakdown].compactMap { $0 }
      }
    } else {
      return [whenSentBreakdown, onChainNetworkFeesBreakdown].compactMap { $0 }
    }
  }

  var breakdownItems: [TransactionBreakdownItem] {
    var results = breakdownAmounts.map { TransactionBreakdownItem(amount: $0) }

    if let count = onChainConfirmations, !isLightningWithdrawal {
      results.append(TransactionBreakdownItem(confirmations: count) )
    }

    return results
  }

  // MARK: Breakdown amounts
  private var totalSentAmounts: ConvertedAmounts? {
    return amounts.netAtCurrent
  }

  private var whenSentAmounts: ConvertedAmounts? {
    return amounts.netWhenInitiated ?? amounts.netWhenTransacted
  }

  private var totalSentBreakdown: BreakdownAmount? {
    return totalSentAmounts.flatMap { BreakdownAmount(type: .totalSent, amounts: $0, walletTxType: walletTxType) }
  }

  private var totalWithdrawalBreakdown: BreakdownAmount? {
    return amounts.totalWithdrawalAmounts.flatMap { BreakdownAmount(type: .totalWithdrawal(walletTxType), amounts: $0, walletTxType: walletTxType) }
  }

  private var netWithdrawalBreakdown: BreakdownAmount? {
    return amounts.netWithdrawalAmounts.flatMap { BreakdownAmount(type: .netWithdrawal, amounts: $0, walletTxType: walletTxType) }
  }

  private var whenSentBreakdown: BreakdownAmount? {
    return whenSentAmounts.flatMap { BreakdownAmount(type: .whenSent, amounts: $0, walletTxType: walletTxType) }
  }

  private var onChainNetworkFeesBreakdown: BreakdownAmount? {
    return amounts.bitcoinNetworkFee.flatMap { BreakdownAmount(type: .networkFees(paidByDropBit: dropBitPaidNetworkFees),
                                                               amounts: $0, walletTxType: walletTxType) }
  }

  private var dropBitFeesBreakdown: BreakdownAmount? {
    return amounts.dropBitFee.flatMap { BreakdownAmount(type: .dropbitFees, amounts: $0, walletTxType: walletTxType) }
  }

  private var dropBitPaidNetworkFees: Bool {
    return isLightningDeposit
  }

}

struct BreakdownAmount {
  let type: BreakdownItemType
  let amounts: ConvertedAmounts
  let walletTxType: WalletTransactionType

  var title: String {
    return type.title
  }

  var detail: String {
    let btcString = btcFormatter.string(fromDecimal: amounts.btc) ?? ""
    let fiatString = fiatFormatter.string(fromDecimal: amounts.fiat) ?? ""
    if case .networkFees(let paidByDropBit) = type, paidByDropBit {
      return "Paid by DropBit (\(fiatString))"
    } else {
      return "\(btcString) (\(fiatString))"
    }
  }

  private var btcFormatter: CKCurrencyFormatter {
    switch walletTxType {
    case .onChain:    return BitcoinFormatter(symbolType: .string)
    case .lightning:  return SatsFormatter()
    }
  }

  private var fiatFormatter: FiatFormatter {
    return FiatFormatter(currency: amounts.fiatCurrency, withSymbol: true, showNegativeSymbol: false)
  }

}

struct TransactionBreakdownItem {
  var title: String
  var detail: String

  init(amount: BreakdownAmount) {
    self.title = amount.title
    self.detail = amount.detail
  }

  init(confirmations: Int) {
    self.title = "Confirmations"
    self.detail = confirmations >= 6 ? "6+" : String(describing: confirmations)
  }
}

enum BreakdownItemType {
  case totalWithdrawal(WalletTransactionType)
  case netWithdrawal
  case totalSent
  case networkFees(paidByDropBit: Bool)
  case dropbitFees
  case whenSent
  case total

  var title: String {
    switch self {
    case .netWithdrawal:    return "Transferred"
    case .totalSent:        return "Total Sent"
    case .whenSent:         return "When Sent"
    case .networkFees:      return "Network Fee"
    case .dropbitFees:      return "DropBit Fee"
    case .total:            return "Total"
    case .totalWithdrawal(let walletTxType):
      switch walletTxType {
      case .onChain:        return "Amount"
      case .lightning:      return "Total Sent"
      }
    }
  }
}
