//
//  MockTransactionHistoryDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

typealias MockTransactionVM = MockTransactionHistoryDetailCellViewModel

struct MockTransactionHistoryDetailCellViewModel: TransactionHistoryDetailCellViewModelType {

  let accountType: AccountType
  let direction: TransactionDirection
  let statusDescription: String
  let isValidTransaction: Bool
  let recipientDescription: String?
  let bitcoinAddress: String?

  let amountDetails: AmountDisplayDetails
  let progressBarDetails: ProgressBarDetails?
  let twitterDetails: TwitterDisplayDetails?
  let lightningInvoiceDetails: LightningInvoiceDisplayDetails?
  let memoDetails: MemoDisplayDetails?
  let action: TransactionDetailAction?

  init(type: AccountType,
       direction: TransactionDirection,
       status: String,
       recipient: String?,
       address: String?,
       amount: AmountDisplayDetails,
       memo: MemoDisplayDetails?,
       action: TransactionDetailAction?,
       progress: ProgressBarDetails? = nil,
       twitter: TwitterDisplayDetails? = nil,
       invoice: LightningInvoiceDisplayDetails? = nil,
       isValid: Bool = true) {

    self.accountType = type
    self.direction = direction
    self.statusDescription = status
    self.isValidTransaction = isValid
    self.recipientDescription = recipient
    self.bitcoinAddress = address
    self.amountDetails = amount
    self.progressBarDetails = progress
    self.twitterDetails = twitter
    self.lightningInvoiceDetails = invoice
    self.memoDetails = memo
    self.action = action
  }
}

struct MockTransactionHistoryDataSource {

  let transactionViewModels: [TransactionHistoryDetailCellViewModelType] = [
    
  ]

}
