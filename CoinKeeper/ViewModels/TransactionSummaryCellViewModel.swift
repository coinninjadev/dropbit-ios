//
//  TransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

struct TransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {
  var selectedCurrency: SelectedCurrency

  var walletTxType: WalletTransactionType

  var isValidTransaction: Bool

  var date: Date

  var isLightningTransfer: Bool

  var status: TransactionStatus

  var memo: String?

  var amountDetails: TransactionAmountDetails

  var direction: TransactionDirection

  var statusTextColor: UIColor

  var counterpartyDescription: String?

  var amountLabels: DetailCellAmountLabels

  var twitterConfig: TransactionCellTwitterConfig?

}
