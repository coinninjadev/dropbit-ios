//
//  MockTransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockTransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {

  let walletTxType: WalletTransactionType
  let direction: TransactionDirection
  let isValidTransaction: Bool
  let status: TransactionStatus
  let date: Date
  let isLightningTransfer: Bool
  let selectedCurrency: SelectedCurrency
  let amountDetails: TransactionAmountDetails
  let counterpartyDescription: String?
  let twitterConfig: TransactionCellTwitterConfig?
  let memo: String?

  init(walletTxType: WalletTransactionType,
       direction: TransactionDirection,
       isValid: Bool,
       status: TransactionStatus,
       date: Date,
       isLightningTransfer: Bool,
       selectedCurrency: SelectedCurrency,
       amountDetails: TransactionAmountDetails,
       counterpartyDescription: String?,
       twitterConfig: TransactionCellTwitterConfig?,
       memo: String?) {
    self.walletTxType = walletTxType
    self.direction = direction
    self.isValidTransaction = isValid
    self.status = status
    self.date = date
    self.isLightningTransfer = isLightningTransfer
    self.selectedCurrency = selectedCurrency
    self.amountDetails = amountDetails
    self.counterpartyDescription = counterpartyDescription
    self.twitterConfig = twitterConfig
    self.memo = memo
  }

}
