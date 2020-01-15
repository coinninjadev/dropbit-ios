//
//  AppCoordinator+EmptyStateLightningLoadDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: EmptyStateLightningLoadDelegate {

  func didRequestLightningLoad(withAmount amount: TransferAmount) {
    let dollars = NSDecimalNumber(integerAmount: amount.value, currency: .USD)
    trackReloaded(amount: amount)
    self.lightningPaymentData(forFiatAmount: dollars, isMax: false)
      .done { paymentData in
        let rates = self.currencyController.exchangeRates
        let viewModel = WalletTransferViewModel(direction: .toLightning(paymentData), amount: amount, exchangeRates: rates)
        let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel,
                                                                                    alertManager: self.alertManager)
        self.navigationController.present(walletTransferViewController, animated: true, completion: nil)
      }
      .catch { self.handleLightningLoadError($0) }
  }

  func handleLightningLoadError(_ error: DisplayableError) {
    let defaultDuration = 4.0
    if let validationError = error as? BitcoinAddressValidatorError {
      let message = validationError.displayMessage + "\n\nThere was a problem obtaining a valid payment address.\n\nPlease try again later."
      alertManager.showErrorHUD(message: message, forDuration: defaultDuration)
    } else if let txDataError = error as? TransactionDataError {
      alertManager.showErrorHUD(txDataError, forDuration: defaultDuration)
    } else if let validationError = error as? LightningWalletAmountValidatorError {
      alertManager.showErrorHUD(validationError, forDuration: defaultDuration)
    } else {
      alertManager.showErrorHUD(error, forDuration: defaultDuration)
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
