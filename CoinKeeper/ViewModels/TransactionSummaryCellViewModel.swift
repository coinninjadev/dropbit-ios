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
  var walletTxType: WalletTransactionType
  var selectedCurrency: SelectedCurrency
  var direction: TransactionDirection
  var isLightningTransfer: Bool
  var status: TransactionStatus
  var amountDetails: TransactionAmountDetails
  var memo: String?

  var counterpartyConfig: TransactionCellCounterpartyConfig?
  var receiverAddress: String?
  var lightningInvoice: String?

  init(managedTx: CKMTransaction,
       selectedCurrency: SelectedCurrency,
       lightningLoadAddress: String?) {
    self.walletTxType = .onChain
    self.selectedCurrency = selectedCurrency
    self.direction = managedTx.isIncoming ? .in : .out


    self.memo = managedTx.memo
  }

}
