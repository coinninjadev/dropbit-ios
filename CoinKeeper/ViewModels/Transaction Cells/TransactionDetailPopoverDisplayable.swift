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
  var breakdownSentAmountText: String? { get }
  var breakdownFeeAmountText: String? { get }
  var confirmationsText: String? { get }
  var detailStatusText: String? { get }
  var txid: String? { get }
  var txidURL: URL? { get }
}

protocol TransactionDetailPopoverViewModelType: TransactionDetailPopoverDisplayable {
  var txidIsActualTxid: Bool { get }
  var walletTxType: WalletTransactionType { get }
  var confirmations: Int? { get }
  var amounts: TransactionAmounts { get }
}

extension TransactionDetailPopoverViewModelType {
  var confirmationsText: String? {
    guard let count = confirmations else { return nil }
    return count >= 6 ? "6+" : String(describing: count)
  }

  var txidURL: URL? {
    guard let txid = txid, txidIsActualTxid else { return nil }
    return CoinNinjaUrlFactory.buildUrl(for: .transaction(id: txid))
  }
}
