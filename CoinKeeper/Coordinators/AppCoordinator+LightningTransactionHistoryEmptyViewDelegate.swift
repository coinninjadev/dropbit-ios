//
//  AppCoordinator+LightningTransactionHistoryEmptyViewDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: LightningTransactionHistoryEmptyViewDelegate {

  func emptyViewDidRequestRefill(withAmount amount: TransferAmount) {
    let viewModel = WalletTransferViewModel(transferType: .toLightning, amount: amount)
    let walletTransferViewController = WalletTransferViewController.newInstance(delegate: self, viewModel: viewModel)
    navigationController.present(walletTransferViewController, animated: true, completion: nil)
  }
}
