//
//  AppCoordinator+LightningReloadDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningReloadDelegate {

  func didRequestLightningLoad(withAmount amount: TransferAmount) {
    let dollars = NSDecimalNumber(integerAmount: amount.value, currency: .USD)
    let exchangeRates = self.currencyController.exchangeRates
    let currencyPair = CurrencyPair(primary: .USD, fiat: .USD)
    let converter = CurrencyConverter(rates: exchangeRates, fromAmount: dollars, currencyPair: currencyPair)
    guard let btcAmount = converter.convertedAmount() else { return }
    let context = self.persistenceManager.viewContext
    self.buildLoadLightningPaymentData(btcAmount: btcAmount, exchangeRates: exchangeRates, in: context)
      .done { paymentData in
        let viewModel = WalletTransferViewModel(direction: .toLightning(paymentData), amount: amount, exchangeRates: exchangeRates)
        let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
        self.navigationController.present(walletTransferViewController, animated: true, completion: nil)
    }.cauterize()
  }

}
