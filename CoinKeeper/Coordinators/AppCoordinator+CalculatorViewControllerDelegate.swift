//
//  AppCoordinator+CalculatorViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: CalculatorViewControllerDelegate {
  func viewControllerDidTapSendPaymentWithInvalidAmount(_ viewController: UIViewController, error: ValidatorTypeError) {
    let alert = alertManager.defaultAlert(withTitle: "Invalid Amount", description: error.displayMessage)
    navigationController.topViewController()?.present(alert, animated: true, completion: nil)
  }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) {
    analyticsManager.track(event: .scanQRButtonPressed, with: nil)
    permissionManager.requestPermission(for: .camera) { [weak self] status in
      switch status {
      case .authorized:
        self?.showScanViewController(fallbackBTCAmount: converter.btcValue, primaryCurrency: converter.fromCurrency)
      default:
        break
      }
    }
  }

  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter) {
    guard let wmgr = walletManager else { return }
    analyticsManager.track(event: .requestButtonPressed, with: nil)
    let requestViewController = RequestPayViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: requestViewController)

    var nextAddress: String?
    let bgContext = persistenceManager.createBackgroundContext()
    bgContext.performAndWait {
      guard let receiveAddress = wmgr.createAddressDataSource().nextAvailableReceiveAddress(forServerPool: false,
                                                                                            indicesToSkip: [],
                                                                                            in: bgContext)?.address else { return }
      nextAddress = receiveAddress
    }

    guard let address = nextAddress else { return }
    let viewModel = RequestPayViewModel(receiveAddress: address, currencyConverter: converter)
    requestViewController.viewModel = viewModel
    viewController.present(requestViewController, animated: true, completion: nil)
  }

  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter) {
    analyticsManager.track(event: .payButtonWasPressed, with: nil)
    let sendPaymentViewController = SendPaymentViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: sendPaymentViewController)
    sendPaymentViewController.alertManager = self.alertManager
    sendPaymentViewController.viewModel = SendPaymentViewModel(btcAmount: converter.btcValue,
                                                               primaryCurrency: converter.fromCurrency)
    navigationController.present(sendPaymentViewController, animated: true)
  }

  func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) {
    self.badgeManager.publishBadgeUpdate()
  }

}
