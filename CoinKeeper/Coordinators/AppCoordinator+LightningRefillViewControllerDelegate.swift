//
//  AppCoordinator+LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningRefillViewControllerDelegate {

  func amountButtonWasTouched(amount: TransferAmount) {
    showTransferViewController(withAmount: amount)
  }

  func dontAskMeAgainButtonWasTouched() {
    persistenceManager.brokers.preferences.dontShowLightningRefill = true
  }

  private func showTransferViewController(withAmount amount: TransferAmount) {
    let viewModel = WalletTransferViewModel(direction: .toLightning, amount: amount)
    let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
    navigationController.present(walletTransferViewController, animated: true, completion: nil)
  }
}
