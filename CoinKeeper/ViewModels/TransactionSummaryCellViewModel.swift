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

  var status: TransactionStatus

  var isValidTransaction: Bool

  var isLightningTransfer: Bool

  var btcAddress: String?

  var lightningInvoice: String?

  var memo: String?

  var amountDetails: TransactionAmountDetails

  var direction: TransactionDirection

  var counterpartyConfig: TransactionCellCounterpartyConfig?

}
