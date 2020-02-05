//
//  AppCoordinator+URLs.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator {

  func handleLaunchUrlIfNecessary() {
    guard let launchType = launchUrl, launchStateManager.userAuthenticated else { return }

    switch launchType {
    case .bitcoin(let bitcoinURL):
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
    case .wyre(let url):
      analyticsManager.track(event: .quickPaySuccessReturn, with: nil)
      if let top = navigationController.topViewController(), top is GetBitcoinViewController {
        navigationController.popViewController(animated: true)
      }
      let transferID = url.transferID
      let controller = GetBitcoinSuccessViewController.newInstance(withDelegate: self, transferID: transferID)
      controller.modalPresentationStyle = .overFullScreen
      controller.modalTransitionStyle = .crossDissolve
      navigationController.topViewController()?.present(controller, animated: true, completion: nil)
    case .widget:
      analyticsManager.track(event: .widgetOpenApp, with: nil)
      didTapChartsButton()
    default:
      return
    }

    launchUrl = nil
  }
}
