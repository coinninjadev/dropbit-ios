//
//  MockTransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

typealias MockSummaryCellVM = MockTransactionSummaryCellViewModel
class MockTransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {

  var walletTxType: WalletTransactionType
  var direction: TransactionDirection
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
       status: TransactionStatus,
       isLightningTransfer: Bool,
       btcAddress: String?,
       lightningInvoice: String?,
       selectedCurrency: SelectedCurrency,
       amountDetails: TransactionAmountDetails,
       counterpartyConfig: TransactionCellCounterpartyConfig?,
       memo: String?) {
    self.walletTxType = walletTxType
    self.direction = direction
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
    let btcAmount = NSDecimalNumber(integerAmount: sats, currency: .BTC)
    return TransactionAmountDetails(btcAmount: btcAmount, fiatCurrency: .USD, exchangeRates: testRates)
  }

  static func testAmountDetails(cents: Int) -> TransactionAmountDetails {
    let usdAmount = NSDecimalNumber(integerAmount: cents, currency: .USD)
    return TransactionAmountDetails(fiatAmount: usdAmount, fiatCurrency: .USD, exchangeRates: testRates)
  }

  static func defaultInstance() -> MockTransactionSummaryCellViewModel {
    let amtDetails = testAmountDetails(sats: 49500)
    let address = mockValidBitcoinAddress()
    return MockTransactionSummaryCellViewModel(walletTxType: .onChain, direction: .out,
                                               status: .completed, isLightningTransfer: false,
                                               btcAddress: address, lightningInvoice: nil,
                                               selectedCurrency: .fiat, amountDetails: amtDetails,
                                               counterpartyConfig: nil, memo: nil)
  }

  static func testInstance(walletTxType: WalletTransactionType = .onChain,
                           direction: TransactionDirection = .out,
                           status: TransactionStatus = .completed,
                           isLightningTransfer: Bool = false,
                           btcAddress: String? = nil,
                           lightningInvoice: String? = nil,
                           selectedCurrency: SelectedCurrency = .fiat,
                           amountDetails: TransactionAmountDetails? = nil,
                           counterpartyConfig: TransactionCellCounterpartyConfig? = nil,
                           memo: String? = nil) -> MockTransactionSummaryCellViewModel {

    let amtDetails = amountDetails ?? MockTransactionSummaryCellViewModel.testAmountDetails(sats: 49500)
    return MockTransactionSummaryCellViewModel(
      walletTxType: walletTxType, direction: direction,
      status: status, isLightningTransfer: isLightningTransfer,
      btcAddress: btcAddress, lightningInvoice: lightningInvoice,
      selectedCurrency: selectedCurrency, amountDetails: amtDetails,
      counterpartyConfig: counterpartyConfig, memo: memo)
  }

  static func mockTwitterConfig() -> TransactionCellTwitterConfig {
    let avatar = UIImage(named: "testAvatar")!
    return TransactionCellTwitterConfig(avatar: avatar, displayHandle: "@satoshi")
  }

  static func mockValidBitcoinAddress() -> String {
    #if DEBUG
    return "2N9yokkV146gEoHT6sgUNtisEd7GH93PQ8Q"
    #else
    return "15PCeM6EN7ihm4QzhVfZCeZis7uggr5RRJ"
    #endif
  }

}
