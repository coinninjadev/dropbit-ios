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
      guard let self = self, !item.isOkButton else { return }
      let direction: TransferDirection = item == toLightningItem ? .toLightning(nil) : .toOnChain(nil)
      switch direction {
      case .toLightning:
        do {
          let vm = try self.createQuickLoadViewModel()
          let vc = LightningQuickLoadViewController.newInstance(viewModel: vm, delegate: self)
          vc.modalPresentationStyle = .overCurrentContext
          vc.modalTransitionStyle = .crossDissolve
          viewController.present(vc, animated: true, completion: nil)

        } catch {
          log.warn(error.localizedDescription)
          self.showQuickLoadBalanceError(for: error, viewController: viewController)
        }

      case .toOnChain:
        let exchangeRates = self.currencyController.exchangeRates
        let viewModel = WalletTransferViewModel(direction: direction, amount: .custom, exchangeRates: exchangeRates)
        let transferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
        self.toggleChartAndBalance()
        self.navigationController.present(transferViewController, animated: true, completion: nil)
      }
    }

    alertManager.showActionSheet(in: viewController, with: [toLightningItem, toOnChainItem], actions: actions)
  }

  private func createQuickLoadViewModel() throws -> LightningQuickLoadViewModel {
    let balances = self.spendableBalancesNetPending()
    let rates = self.currencyController.exchangeRates
    return try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, fiatCurrency: .USD)
  }

  private func showQuickLoadBalanceError(for error: Error, viewController: UIViewController) {
    func showDefaultAlert(withMessage message: String) {
      self.alertManager.showError(message: message, forDuration: 5)
    }

    if let validatorError = error as? LightningWalletAmountValidatorError {
      switch validatorError {
      case .reloadMinimum:
        let message = """
        DropBit requires you to load a minimum of $5.00 to your Lightning wallet.
        You don’t currently have enough funds to meet the minimum requirement.
        """.removingMultilineLineBreaks()

        let buyBitcoinAction = AlertActionConfiguration(title: "Buy Bitcoin", style: .default) {
          self.viewControllerDidTapGetBitcoin(viewController)
        }

        let alertVM = AlertControllerViewModel(title: nil, description: message, actions: [buyBitcoinAction,
                                                                                           alertManager.okAlertActionConfig])
        let alert = self.alertManager.alert(from: alertVM)
        self.navigationController.present(alert, animated: true, completion: nil)
      default:
        let message = validatorError.displayMessage ?? validatorError.localizedDescription
        showDefaultAlert(withMessage: message)
      }

    } else {
      showDefaultAlert(withMessage: error.localizedDescription)
    }
  }

  func viewControllerDidRequestPrimaryCurrencySwap() {
    currencyController.selectedCurrency.toggle()
    persistenceManager.brokers.preferences.selectedCurrency = currencyController.selectedCurrency
  }

  func viewControllerDidTapWalletTooltip() {
    navigationController.present(LightningTooltipViewController.newInstance(), animated: true, completion: nil)
  }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) {
    guard showLightningLockAlertIfNecessary() else { return }
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

  func viewControllerDidTapReceivePayment(_ viewController: UIViewController,
                                          converter: CurrencyConverter, walletTransactionType: WalletTransactionType) {
    guard showLightningLockAlertIfNecessary() else { return }
    if let requestViewController = createRequestPayViewController(converter: converter) {
      switch walletTransactionType {
      case .onChain:
        analyticsManager.track(event: .requestButtonPressed, with: nil)
      case .lightning:
        analyticsManager.track(event: .lightningReceivePressed, with: nil)
      }

      viewController.present(requestViewController, animated: true, completion: nil)
    }
  }

  func viewControllerDidTapSendPayment(_ viewController: UIViewController,
                                       converter: CurrencyConverter,
                                       walletTransactionType: WalletTransactionType) {
    guard showLightningLockAlertIfNecessary() else { return }
    toggleChartAndBalance()
    switch walletTransactionType {
    case .onChain:
      analyticsManager.track(event: .payButtonWasPressed, with: nil)
    case .lightning:
      analyticsManager.track(event: .lightningSendPressed, with: nil)
    }

    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                           primaryAmount: converter.fromAmount,
                                                           walletTransactionType: walletTransactionType,
                                                           currencyPair: self.currencyController.currencyPair)
    let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: swappableVM, walletTransactionType: walletTransactionType)
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM, alertManager: alertManager)
    navigationController.present(sendPaymentViewController, animated: true)
  }

}

extension AppCoordinator: LightningQuickLoadViewControllerDelegate {

  func viewControllerDidRequestCustomAmountLoad(_ viewController: LightningQuickLoadViewController) {
    viewController.dismiss(animated: true) {
      let exchangeRates = self.currencyController.exchangeRates
      let viewModel = WalletTransferViewModel(direction: .toLightning(nil), amount: .custom, exchangeRates: exchangeRates)
      let transferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
      self.toggleChartAndBalance()
      self.navigationController.present(transferViewController, animated: true, completion: nil)
    }
  }

}
