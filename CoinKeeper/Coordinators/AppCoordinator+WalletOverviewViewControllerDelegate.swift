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
import Sheeeeeeeeet

extension AppCoordinator: WalletOverviewViewControllerDelegate {

  func setSelectedWalletTransactionType(_ viewController: UIViewController, to selectedType: WalletTransactionType) {
    persistenceManager.brokers.preferences.selectedWalletTransactionType = selectedType
  }

  func selectedWalletTransactionType() -> WalletTransactionType {
    return persistenceManager.brokers.preferences.selectedWalletTransactionType
  }

  func viewControllerDidChangeSelectedWallet(_ viewController: UIViewController, to selectedType: WalletTransactionType) {
    persistenceManager.brokers.preferences.selectedWalletTransactionType = selectedType
  }

  func viewControllerDidSelectTransfer(_ viewController: UIViewController) {
    let toLightningItem = ActionSheetItem(title: "Load Lightning Wallet")
    let toOnChainItem = ActionSheetItem(title: "Withdraw From Lightning Wallet")
    let actions: ActionSheet.SelectAction = { [weak self] sheet, item in
      guard let strongSelf = self, !item.isOkButton else { return }
      let direction: TransferDirection = item == toLightningItem ? .toLightning(nil) : .toOnChain(nil)
      let balances = strongSelf.spendableBalanceNetPending()
      let exchangeRates = strongSelf.currencyController.exchangeRates
      let viewModel = WalletTransferViewModel(direction: direction, amount: .custom,
                                              walletBalances: balances, exchangeRates: exchangeRates)
      let transferViewController = WalletTransferViewController.newInstance(delegate: strongSelf, viewModel: viewModel)
      strongSelf.toggleChartAndBalance()
      strongSelf.navigationController.present(transferViewController, animated: true, completion: nil)
    }

    alertManager.showActionSheet(in: viewController, with: [toLightningItem, toOnChainItem], actions: actions)
  }

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
    toggleChartAndBalance()
    analyticsManager.track(event: .payButtonWasPressed, with: nil)

    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                           primaryAmount: converter.fromAmount,
                                                           walletTransactionType: walletTransactionType,
                                                           currencyPair: self.currencyController.currencyPair)
    let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: swappableVM, walletTransactionType: walletTransactionType)
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM)
    sendPaymentViewController.alertManager = self.alertManager
    navigationController.present(sendPaymentViewController, animated: true)
  }

}
