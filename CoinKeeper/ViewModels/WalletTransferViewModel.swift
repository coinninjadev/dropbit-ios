//
//  WalletTransferViewModel.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class WalletTransferViewModel: CurrencySwappableEditAmountViewModel {

  var transferType: WalletTransferViewController.TransferType
  var amount: TransferAmount

  init(transferType: WalletTransferViewController.TransferType, amount: TransferAmount) {
    self.transferType = transferType
    self.amount = amount
    super.init(exchangeRates: ExchangeRateManager().exchangeRates,
               primaryAmount: NSDecimalNumber(integerAmount: amount.value, currency: .USD),
               currencyPair: CurrencyPair(primary: .USD, fiat: .USD))
  }
}
