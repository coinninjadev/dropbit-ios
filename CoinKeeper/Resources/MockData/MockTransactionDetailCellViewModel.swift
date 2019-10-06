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

  let date: Date
  let memoIsShared: Bool
  let invitationStatus: InvitationStatus?
  let onChainConfirmations: Int?
  let addressProvidedToSender: String?
  let paymentIdIsValid: Bool
  let exchangeRateWhenReceived: Double?

  init(walletTxType: WalletTransactionType = .onChain,
       direction: TransactionDirection = .out,
       status: TransactionStatus = .completed,
       onChainConfirmations: Int? = nil,
       isSentToSelf: Bool = false,
       isLightningTransfer: Bool = false,
       receiverAddress: String? = nil,
       addressProvidedToSender: String? = nil,
       lightningInvoice: String? = nil,
       selectedCurrency: SelectedCurrency = .fiat,
       amountFactory: MockAmountsFactory? = nil,
       counterpartyConfig: TransactionCellCounterpartyConfig? = nil,
       invitationStatus: InvitationStatus? = nil,
       memo: String? = nil,
       memoIsShared: Bool = false,
       date: Date = Date()) {

    let amtFactory = amountFactory ?? MockTransactionSummaryCellViewModel.testAmountFactory(sats: 49500)

    self.date = date
    self.memoIsShared = memoIsShared
    self.invitationStatus = invitationStatus
    self.onChainConfirmations = onChainConfirmations
    self.addressProvidedToSender = addressProvidedToSender
    self.paymentIdIsValid = MockDetailCellVM.paymentIdIsValid(basedOn: invitationStatus)
    self.exchangeRateWhenReceived = MockDetailCellVM.testRates[.USD].flatMap { $0 - 50 }

    super.init(walletTxType: walletTxType, direction: direction, status: status, isSentToSelf: isSentToSelf,
               isLightningTransfer: isLightningTransfer, receiverAddress: receiverAddress,
               lightningInvoice: lightningInvoice, selectedCurrency: selectedCurrency,
               amountFactory: amtFactory, counterpartyConfig: counterpartyConfig, memo: memo)
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

class MockTransactionDetailInvoiceCellViewModel: MockTransactionDetailValidCellViewModel, TransactionDetailInvoiceCellViewModelType {

  let qrCodeGenerator: QRCodeGenerator
  let hoursUntilExpiration: Int?

  init(hoursUntilExpiration: Int?) {
    self.qrCodeGenerator = QRCodeGenerator()
    self.hoursUntilExpiration = hoursUntilExpiration

    let amountFactory = MockDetailCellVM.testAmountFactory(cents: 520)
    super.init(walletTxType: .lightning, direction: .in, status: .pending,
               lightningInvoice: MockDetailCellVM.mockLightningInvoice(),
               selectedCurrency: .fiat, amountFactory: amountFactory,
               memo: "Coffee ☕️", memoIsShared: true, date: Date())
  }

}
