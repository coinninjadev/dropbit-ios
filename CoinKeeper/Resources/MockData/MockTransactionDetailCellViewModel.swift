//
//  MockTransactionDetailCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 9/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

typealias MockDetailCellVM = MockTransactionDetailValidCellViewModel
class MockTransactionDetailValidCellViewModel: MockTransactionSummaryCellViewModel, TransactionDetailCellViewModelType {

  var date: Date
  var memoIsShared: Bool
  var invitationStatus: InvitationStatus?
  var onChainConfirmations: Int?
  var addressProvidedToSender: String?
  var encodedInvoice: String?
  var paymentIdIsValid: Bool
  var exchangeRateWhenReceived: Double?

  init(walletTxType: WalletTransactionType = .onChain,
       direction: TransactionDirection = .out,
       status: TransactionStatus = .completed,
       onChainConfirmations: Int? = nil,
       isLightningTransfer: Bool = false,
       receiverAddress: String? = nil,
       addressProvidedToSender: String? = nil,
       lightningInvoice: String? = nil,
       selectedCurrency: SelectedCurrency = .fiat,
       amountDetails: TransactionAmountDetails? = nil,
       counterpartyConfig: TransactionCellCounterpartyConfig? = nil,
       invitationStatus: InvitationStatus? = nil,
       memo: String? = nil,
       memoIsShared: Bool = false,
       date: Date = Date()) {

    let amtDetails = amountDetails ?? MockTransactionSummaryCellViewModel.testAmountDetails(sats: 49500)

    self.date = date
    self.memoIsShared = memoIsShared
    self.invitationStatus = invitationStatus
    self.onChainConfirmations = onChainConfirmations
    self.addressProvidedToSender = addressProvidedToSender
    self.paymentIdIsValid = MockDetailCellVM.paymentIdIsValid(basedOn: invitationStatus)

    super.init(walletTxType: walletTxType, direction: direction, status: status,
               isLightningTransfer: isLightningTransfer, receiverAddress: receiverAddress,
               lightningInvoice: lightningInvoice, selectedCurrency: selectedCurrency,
               amountDetails: amtDetails, counterpartyConfig: counterpartyConfig, memo: memo)
  }

  /// Use this proxy function to prevent test from entering conflicting information for invitationStatus and paymentIdIsValid
  private static func paymentIdIsValid(basedOn status: InvitationStatus?) -> Bool {
    guard let status = status else { return true }
    switch status {
    case .completed:  return true
    default:          return false
    }
  }

  func exchangeRateWhenReceived(forCurrency currency: CurrencyCode) -> Double? {
    return exchangeRateWhenReceived
  }

}

typealias MockDetailInvalidCellVM = MockTransactionDetailInvalidCellViewModel
class MockTransactionDetailInvalidCellViewModel: MockTransactionDetailValidCellViewModel, TransactionDetailInvalidCellViewModelType {

  init(status: TransactionStatus) {
    super.init(status: status)
  }

  init(dropBitWith walletTxType: WalletTransactionType,
       direction: TransactionDirection,
       identity: UserIdentityType,
       invitationStatus: InvitationStatus,
       transactionStatus: TransactionStatus) {
    super.init(walletTxType: walletTxType,
               direction: direction,
               status: transactionStatus,
               counterpartyConfig: identity.testCounterparty,
               invitationStatus: invitationStatus)
  }
}
