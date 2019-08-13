//
//  AppCoordinator+LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningRefillViewControllerDelegate {

  func lowAmountButtonWasTouched() {
    showTransferViewController(withAmount: .low)
  }

  func mediumAmountButtonWasTouched() {
    showTransferViewController(withAmount: .medium)
  }

  func maxAmountButtonWasTouched() {
    showTransferViewController(withAmount: .max)
  }

  func customAmountButtonWasTouched() {
    showTransferViewController(withAmount: .custom)
  }

  func dontAskMeAgainButtonWasTouched() {
    persistenceManager.brokers.preferences.dontShowLightningRefill = true
  }

  private func showTransferViewController(withAmount amount: TransferAmount) {
    let viewModel = WalletTransferViewModel(transferType: .toLightning, amount: amount)
    let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
    navigationController.present(walletTransferViewController, animated: true, completion: nil)
  }
}
