//
//  AppCoordinator+URLs.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator {

  func handlePendingBitcoinURL() {
    guard let bitcoinURL = bitcoinURLToOpen, launchStateManager.userAuthenticated else { return }
    bitcoinURLToOpen = nil

    if let topVC = navigationController.topViewController(), let sendPaymentVC = topVC as? SendPaymentViewController {
      sendPaymentVC.applyRecipient(inText: bitcoinURL.absoluteString)

    } else {
      let currencyPair = CurrencyPair(btcPrimaryWith: self.currencyController)
      let vm = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                    primaryAmount: .zero,
                                                    currencyPair: currencyPair)
      let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: vm, walletType: .onChain)
      let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM)
      sendPaymentViewController.alertManager = alertManager
      sendPaymentViewController.recipientDescriptionToLoad = bitcoinURL.absoluteString
      navigationController.present(sendPaymentViewController, animated: true)
    }
  }

}
