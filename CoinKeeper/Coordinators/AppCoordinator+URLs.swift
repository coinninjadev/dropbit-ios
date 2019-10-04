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
                                                    walletTransactionType: .onChain,
                                                    currencyPair: currencyPair)
      let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: vm, walletTransactionType: .onChain)
      let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM, alertManager: alertManager)
      sendPaymentVM.delegate = sendPaymentViewController
      sendPaymentViewController.recipientDescriptionToLoad = bitcoinURL.absoluteString
      navigationController.present(sendPaymentViewController, animated: true)
    }
  }

}
