//
//  AppCoordinator+WalletOverviewViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import MMDrawerController

extension AppCoordinator: WalletOverviewViewControllerDelegate {

  func viewControllerDidRequestPrimaryCurrencySwap() {
    currencyController.selectedCurrency.toggle()
  }

  func viewControllerDidTapWalletTooltip() {
    navigationController.present(LightningTooltipViewController.newInstance(), animated: true, completion: nil)
  }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) {
    analyticsManager.track(event: .scanQRButtonPressed, with: nil)
    permissionManager.requestPermission(for: .camera) { [weak self] status in
      switch status {
      case .authorized:
        self?.showScanViewController(fallbackBTCAmount: converter.btcAmount, primaryCurrency: converter.fromCurrency)
      default:
        break
      }
    }
  }

  func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool {
    return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 == 0
  }

  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter) {
    if let requestViewController = createRequestPayViewController(converter: converter) {
      analyticsManager.track(event: .requestButtonPressed, with: nil)
      viewController.present(requestViewController, animated: true, completion: nil)
    }
  }

  func viewControllerDidTapSendPayment(_ viewController: UIViewController,
                                       converter: CurrencyConverter,
                                       walletTransactionType: WalletTransactionType) {
    guard let walletOverviewViewController = viewController as? WalletOverviewViewController else { return }
    walletOverviewViewController.balanceContainer.toggleChartAndBalance()
    analyticsManager.track(event: .payButtonWasPressed, with: nil)

    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                           primaryAmount: converter.fromAmount,
                                                           currencyPair: self.currencyController.currencyPair)
    let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: swappableVM, walletTransactionType: walletTransactionType)
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM)
    sendPaymentViewController.alertManager = self.alertManager
    navigationController.present(sendPaymentViewController, animated: true)
  }

}
