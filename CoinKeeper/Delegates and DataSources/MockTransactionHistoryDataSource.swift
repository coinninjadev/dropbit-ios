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
  let status: TransactionStatus
  let recipientDescription: String?
  let bitcoinAddress: String?
  let date: Date?
  let isValidTransaction: Bool

  let amountDetails: TransactionAmountDetails
  let progressConfig: ProgressBarConfig?
  let twitterConfig: DetailCellTwitterConfig?
  let memoConfig: DetailCellMemoConfig?
  let action: TransactionDetailAction?
  let lightningInvoiceDetails: LightningInvoiceDisplayDetails?

  init(type: AccountType,
       direction: TransactionDirection,
       status: TransactionStatus,
       recipient: String?,
       address: String?,
       date: Date?,
       amount: TransactionAmountDetails,
       memo: DetailCellMemoConfig?,
       action: TransactionDetailAction?,
       progress: ProgressBarConfig? = nil,
       twitter: DetailCellTwitterConfig? = nil,
       invoice: LightningInvoiceDisplayDetails? = nil,
       isValid: Bool = true) {

    self.accountType = type
    self.direction = direction
    self.status = status
    self.recipientDescription = recipient
    self.bitcoinAddress = address
    self.date = date
    self.amountDetails = amount
    self.memoConfig = memo
    self.action = action
    self.progressConfig = progress
    self.twitterConfig = twitter
    self.lightningInvoiceDetails = invoice
    self.isValidTransaction = isValid
  }
}

struct MockTransactionHistoryDataSource {

  let transactionViewModels: [TransactionHistoryDetailCellViewModelType] = [

  ]

}
