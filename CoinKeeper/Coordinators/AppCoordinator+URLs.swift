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
      let sendPaymentViewController = SendPaymentViewController.makeFromStoryboard()
      assignCoordinationDelegate(to: sendPaymentViewController)
      sendPaymentViewController.alertManager = alertManager
      sendPaymentViewController.recipientDescriptionToLoad = bitcoinURL.absoluteString
      sendPaymentViewController.viewModel.updatePrimaryCurrency(to: currencyController.selectedCurrency)
      navigationController.present(sendPaymentViewController, animated: true)
    }
  }

}
