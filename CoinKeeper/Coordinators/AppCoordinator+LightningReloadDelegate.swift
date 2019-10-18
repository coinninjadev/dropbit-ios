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
    trackReloaded(amount: amount)
    let context = self.persistenceManager.viewContext
    self.buildLoadLightningPaymentData(btcAmount: btcAmount, exchangeRates: exchangeRates, in: context)
      .done { paymentData in
        let viewModel = WalletTransferViewModel(direction: .toLightning(paymentData), amount: amount, exchangeRates: exchangeRates)
        let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
        self.navigationController.present(walletTransferViewController, animated: true, completion: nil)
      }
      .catch { self.handleLightningLoadError($0) }
  }

  func handleLightningLoadError(_ error: Error) {
    let defaultDuration = 4.0
    if let validationError = error as? BitcoinAddressValidatorError {
      let message = validationError.debugMessage + "\n\nThere was a problem obtaining a valid payment address.\n\nPlease try again later."
      alertManager.showError(message: message, forDuration: defaultDuration)
    } else if let txDataError = error as? TransactionDataError {
      alertManager.showError(message: txDataError.messageDescription, forDuration: defaultDuration)
    } else if let validationError = error as? LightningWalletAmountValidatorError, let displayMessage = validationError.displayMessage {
      alertManager.showError(message: displayMessage, forDuration: defaultDuration)
    } else {
      alertManager.showError(message: error.localizedDescription, forDuration: defaultDuration)
    }
  }

  private func trackReloaded(amount: TransferAmount) {
    switch amount {
    case .low:
      analyticsManager.track(event: .quickReloadFive, with: nil)
    case .medium:
      analyticsManager.track(event: .quickReloadTwenty, with: nil)
    case .high:
      analyticsManager.track(event: .quickReloadFifty, with: nil)
    case .max:
      analyticsManager.track(event: .quickReloadOneHundred, with: nil)
    case .custom:
      analyticsManager.track(event: .quickReloadCustomAmount, with: nil)
    }
  }

}
