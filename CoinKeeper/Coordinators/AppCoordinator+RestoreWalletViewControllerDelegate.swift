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
    self.saveSuccessfulWords(words: words, isBackedUp: true, flow: .createWallet)
      .get {
        self.analyticsManager.track(event: .restoreWallet, with: nil)
        self.showSuccessFail(forWords: words)
      }.cauterize()
  }

  private func showSuccessFail(forWords words: [String]) {
    let successFailController = SuccessFailViewController.makeFromStoryboard()
    successFailController.viewModel.flow = .restoreWallet
    successFailController.retryCompletion = {
      if let words = self.persistenceManager.walletWords() {
        self.walletManager = WalletManager(words: words, persistenceManager: self.persistenceManager)
        DispatchQueue.main.async {
          successFailController.mode = .success
        }
      } else {
        DispatchQueue.main.async {
          successFailController.mode = .failure
        }
      }
    }
    assignCoordinationDelegate(to: successFailController)
    navigationController.pushViewController(successFailController, animated: true)
    navigationController.orphanDisplayingViewController()
    successFailController.retryCompletion?()
  }

}
