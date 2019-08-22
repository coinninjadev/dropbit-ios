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

  var walletTxType: WalletTransactionType
  var direction: TransactionDirection
  var isValidTransaction: Bool
  var status: TransactionStatus
  var date: Date
  var isLightningTransfer: Bool
  var selectedCurrency: SelectedCurrency
  var amountDetails: TransactionAmountDetails
  var counterpartyDescription: String?
  var twitterConfig: TransactionCellTwitterConfig?
  var memo: String?

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
    return MockTransactionSummaryCellViewModel(walletTxType: .onChain, direction: .out, isValid: true,
                                               status: .completed, date: Date(), isLightningTransfer: false,
                                               selectedCurrency: .fiat, amountDetails: amtDetails,
                                               counterpartyDescription: nil, twitterConfig: nil, memo: nil)
  }

}
