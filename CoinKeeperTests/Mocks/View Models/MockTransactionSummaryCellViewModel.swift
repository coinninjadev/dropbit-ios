//
//  MockTransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
@testable import DropBit

typealias MockSummaryCellVM = MockTransactionSummaryCellViewModel
class MockTransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {

  var walletTxType: WalletTransactionType
  var direction: TransactionDirection
  var isValidTransaction: Bool
  var status: TransactionStatus
  var isLightningTransfer: Bool
  var btcAddress: String?
  var lightningInvoice: String?
  var selectedCurrency: SelectedCurrency
  var amountDetails: TransactionAmountDetails
  var counterpartyConfig: TransactionCellCounterpartyConfig?
  var memo: String?

  init(walletTxType: WalletTransactionType,
       direction: TransactionDirection,
       isValid: Bool,
       status: TransactionStatus,
       date: Date,
       isLightningTransfer: Bool,
       btcAddress: String?,
       lightningInvoice: String?,
       selectedCurrency: SelectedCurrency,
       amountDetails: TransactionAmountDetails,
       counterpartyConfig: TransactionCellCounterpartyConfig?,
       memo: String?) {
    self.walletTxType = walletTxType
    self.direction = direction
    self.isValidTransaction = isValid
    self.status = status
    self.isLightningTransfer = isLightningTransfer
    self.btcAddress = btcAddress
    self.lightningInvoice = lightningInvoice
    self.selectedCurrency = selectedCurrency
    self.amountDetails = amountDetails
    self.counterpartyConfig = counterpartyConfig
    self.memo = memo
  }

  static var testRates: ExchangeRates {
    return [.BTC: 1, .USD: 7000]
  }

  static func testAmountDetails(sats: Int) -> TransactionAmountDetails {
    let pair = CurrencyPair(primary: .BTC, fiat: .USD)
    let btcAmount = NSDecimalNumber(integerAmount: sats, currency: .BTC)
    return TransactionAmountDetails(currencyPair: pair, exchangeRates: testRates, primaryBTCAmount: btcAmount,
                                    fiatWhenCreated: nil, fiatWhenTransacted: nil)
  }

  static func defaultInstance() -> MockTransactionSummaryCellViewModel {
    let amtDetails = testAmountDetails(sats: 49500)
    let address = TestHelpers.mockValidBitcoinAddress()
    return MockTransactionSummaryCellViewModel(walletTxType: .onChain, direction: .out, isValid: true,
                                               status: .completed, date: Date(), isLightningTransfer: false,
                                               btcAddress: address, lightningInvoice: nil,
                                               selectedCurrency: .fiat, amountDetails: amtDetails,
                                               counterpartyConfig: nil, memo: nil)
  }

  static func testInstance(walletTxType: WalletTransactionType = .onChain,
                           direction: TransactionDirection = .out,
                           isValid: Bool = true,
                           status: TransactionStatus = .completed,
                           date: Date = Date(),
                           isLightningTransfer: Bool = false,
                           btcAddress: String? = nil,
                           lightningInvoice: String? = nil,
                           selectedCurrency: SelectedCurrency = .fiat,
                           amountDetails: TransactionAmountDetails? = nil,
                           counterpartyConfig: TransactionCellCounterpartyConfig? = nil,
                           memo: String? = nil) -> MockTransactionSummaryCellViewModel {

    let amtDetails = amountDetails ?? MockTransactionSummaryCellViewModel.testAmountDetails(sats: 49500)
    return MockTransactionSummaryCellViewModel(
      walletTxType: walletTxType, direction: direction, isValid: isValid,
      status: status, date: date, isLightningTransfer: isLightningTransfer,
      btcAddress: btcAddress, lightningInvoice: lightningInvoice,
      selectedCurrency: selectedCurrency, amountDetails: amtDetails,
      counterpartyConfig: counterpartyConfig, memo: memo)
  }

  static func testTwitterConfig() -> TransactionCellTwitterConfig {
    let avatar = UIImage(named: "testAvatar")!
    return TransactionCellTwitterConfig(avatar: avatar, displayHandle: "@satoshi")
  }

}
