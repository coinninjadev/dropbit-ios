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
  var isLightningUpgrade: Bool = false
  var receiverAddress: String?
  var lightningInvoice: String?
  var selectedCurrency: SelectedCurrency
  var amountDetails: TransactionAmountDetails
  var counterpartyConfig: TransactionCellCounterpartyConfig?
  var memo: String?

  init(walletTxType: WalletTransactionType,
       direction: TransactionDirection,
       status: TransactionStatus,
       isLightningTransfer: Bool,
       receiverAddress: String?,
       lightningInvoice: String?,
       selectedCurrency: SelectedCurrency,
       amountDetails: TransactionAmountDetails,
       counterpartyConfig: TransactionCellCounterpartyConfig?,
       memo: String?) {
    self.walletTxType = walletTxType
    self.direction = direction
    self.status = status
    self.isLightningTransfer = isLightningTransfer
    self.receiverAddress = receiverAddress
    self.lightningInvoice = lightningInvoice
    self.selectedCurrency = selectedCurrency
    self.amountDetails = amountDetails
    self.counterpartyConfig = counterpartyConfig
    self.memo = memo
  }

  static var testRates: ExchangeRates {
    return [.BTC: 1, .USD: 8500]
  }

  static func testAmountDetails(sats: Int,
                                fiatWhenInvited: NSDecimalNumber? = nil,
                                fiatWhenTransacted: NSDecimalNumber? = nil) -> TransactionAmountDetails {
    let btcAmount = NSDecimalNumber(integerAmount: sats, currency: .BTC)
    return TransactionAmountDetails(btcAmount: btcAmount, fiatCurrency: .USD, exchangeRates: testRates,
                                    fiatWhenInvited: fiatWhenInvited, fiatWhenTransacted: fiatWhenTransacted)
  }

  static func testAmountDetails(cents: Int,
                                fiatWhenInvited: NSDecimalNumber? = nil,
                                fiatWhenTransacted: NSDecimalNumber? = nil) -> TransactionAmountDetails {
    let usdAmount = NSDecimalNumber(integerAmount: cents, currency: .USD)
    return TransactionAmountDetails(fiatAmount: usdAmount, fiatCurrency: .USD, exchangeRates: testRates,
                                    fiatWhenInvited: fiatWhenInvited, fiatWhenTransacted: fiatWhenTransacted)
  }

  static func defaultInstance() -> MockTransactionSummaryCellViewModel {
    let amtDetails = testAmountDetails(sats: 49500)
    let address = mockValidBitcoinAddress()
    return MockTransactionSummaryCellViewModel(walletTxType: .onChain, direction: .out,
                                               status: .completed, isLightningTransfer: false,
                                               receiverAddress: address, lightningInvoice: nil,
                                               selectedCurrency: .fiat, amountDetails: amtDetails,
                                               counterpartyConfig: nil, memo: nil)
  }

  static func testSummaryInstance(walletTxType: WalletTransactionType = .onChain,
                                  direction: TransactionDirection = .out,
                                  status: TransactionStatus = .completed,
                                  isLightningTransfer: Bool = false,
                                  receiverAddress: String? = nil,
                                  lightningInvoice: String? = nil,
                                  selectedCurrency: SelectedCurrency = .fiat,
                                  amountDetails: TransactionAmountDetails? = nil,
                                  counterpartyConfig: TransactionCellCounterpartyConfig? = nil,
                                  memo: String? = nil) -> MockTransactionSummaryCellViewModel {

    let amtDetails = amountDetails ?? MockTransactionSummaryCellViewModel.testAmountDetails(sats: 49500)
    return MockTransactionSummaryCellViewModel(
      walletTxType: walletTxType, direction: direction,
      status: status, isLightningTransfer: isLightningTransfer,
      receiverAddress: receiverAddress, lightningInvoice: lightningInvoice,
      selectedCurrency: selectedCurrency, amountDetails: amtDetails,
      counterpartyConfig: counterpartyConfig, memo: memo)
  }

  static func mockTwitterCounterparty() -> TransactionCellCounterpartyConfig {
    let twitter = MockDetailCellVM.mockTwitterConfig()
    return TransactionCellCounterpartyConfig(twitterConfig: twitter)
  }

  static func mockTwitterConfig() -> TransactionCellTwitterConfig {
    let avatar = UIImage(named: "testAvatar")!
    return TransactionCellTwitterConfig(avatar: avatar, displayHandle: "@satoshi", displayName: "Satoshi Nakamoto")
  }

  static func mockValidBitcoinAddress() -> String {
    #if DEBUG
    return "2N9yokkV146gEoHT6sgUNtisEd7GH93PQ8Q"
    #else
    return "15PCeM6EN7ihm4QzhVfZCeZis7uggr5RRJ"
    #endif
  }

  static func mockLightningInvoice() -> String {
    return  "lnbcrt9876540n1pw4lj7tpp505qh7vwtvh5s48r4x0fjukekepdhkvcdternv8t7eh99t5" +
            "7emrsqdq5w3jhxapqd9h8vmmfvdjscqzpgxqrrsshudk0hjapln9p3vt9dnuy2nhygrda54whp" +
            "l7ds2jjvczcmr0p8qjej6utg98qmyncq30txmh4fernv33rq2wr34uclvzzxrgf6e5pyqq2d9m90"
  }

}
