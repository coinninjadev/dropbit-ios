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
    if let bitcoinURL = bitcoinURLToOpen, launchStateManager.userAuthenticated {
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
    } else if let urlComponents = purchasedBitcoinComponents, launchStateManager.userAuthenticated {
      purchasedBitcoinComponents = nil
      let title = urlComponents.humanReadableDescription
      let viewModel = AlertControllerViewModel(title: title)
      let alert = alertManager.alert(from: viewModel)
      navigationController.present(alert, animated: true, completion: nil)
    } else {
      return
    }

  }
}
