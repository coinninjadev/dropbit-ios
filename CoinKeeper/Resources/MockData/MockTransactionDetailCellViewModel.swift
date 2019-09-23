//
//  MockTransactionDetailCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 9/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

typealias MockDetailCellVM = MockTransactionDetailCellViewModel
class MockTransactionDetailCellViewModel: MockTransactionSummaryCellViewModel, TransactionDetailCellViewModelType {

  var date: Date

  init(walletTxType: WalletTransactionType,
       direction: TransactionDirection,
       status: TransactionStatus,
       isLightningTransfer: Bool,
       receiverAddress: String?,
       lightningInvoice: String?,
       selectedCurrency: SelectedCurrency,
       amountDetails: TransactionAmountDetails,
       counterpartyConfig: TransactionCellCounterpartyConfig?,
       memo: String?,
       date: Date) {
    self.date = date

    super.init(walletTxType: walletTxType, direction: direction, status: status,
               isLightningTransfer: isLightningTransfer, receiverAddress: receiverAddress,
               lightningInvoice: lightningInvoice, selectedCurrency: selectedCurrency,
               amountDetails: amountDetails, counterpartyConfig: counterpartyConfig, memo: memo)
  }

}
