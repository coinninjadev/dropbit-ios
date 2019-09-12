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
    let converter = CurrencyConverter(rates: ExchangeRateManager().exchangeRates,
                                      fromAmount: dollars,
                                      currencyPair: CurrencyPair(primary: .USD, secondary: .BTC, fiat: .USD))
    guard let btcAmount = converter.convertedAmount() else { return }
    let context = self.persistenceManager.viewContext
    let wallet = CKMWallet.findOrCreate(in: context)
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    let paymentData = buildTransactionData(btcAmount: btcAmount,
                                           address: lightningAccount.address,
                                           exchangeRates: ExchangeRateManager().exchangeRates)
    let viewModel = WalletTransferViewModel(direction: .toLightning(paymentData), amount: amount,
                                            walletBalances: spendableBalanceNetPending())
    let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
    navigationController.present(walletTransferViewController, animated: true, completion: nil)
  }

}
