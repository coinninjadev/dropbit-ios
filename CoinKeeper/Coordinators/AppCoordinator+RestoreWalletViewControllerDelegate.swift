//
//  AppCoordinator+RestoreWalletViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

extension AppCoordinator: RestoreWalletViewControllerDelegate {
  func viewControllerDidSubmitWords(words: [String]) {
    self.saveSuccessfulWords(words: words, didBackUp: true)
      .get {
        self.analyticsManager.track(event: .restoreWallet, with: nil)
        self.showSuccessFail(forWords: words)
      }.cauterize()
  }

  private func showSuccessFail(forWords words: [String]) {
    let viewModel = RestoreWalletSuccessFailViewModel(mode: .pending)
    viewModel.shouldShowCloseButton = false
    let successFailController = SuccessFailViewController.newInstance(viewModel: viewModel,
                                                                      delegate: self)
    successFailController.action = {
      if let words = self.persistenceManager.walletWords() {
        self.walletManager = WalletManager(words: words, persistenceManager: self.persistenceManager)
        successFailController.setMode(.success)
      } else {
        successFailController.setMode(.failure)
      }
    }

    navigationController.pushViewController(successFailController, animated: true)
    navigationController.orphanDisplayingViewController()
    navigationController.setNavigationBarHidden(true, animated: false)
    successFailController.action?()
  }

}
