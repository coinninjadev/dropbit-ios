//
//  AppCoordinator+CreateRecoveryWordsViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: CreateRecoveryWordsViewControllerDelegate {
  func viewController(_ viewController: UIViewController, didFinishWords words: [String], in flow: RecoveryWordsFlow) {
    switch flow {
    case .createWallet:
      showVerifyWordsViewController(in: navigationController, with: words, in: flow)
    case .settings:
      switch wordsBackedUp {
      case true:
        viewController.dismiss(animated: true, completion: nil)
      case false:
        guard let navigationController = viewController.navigationController else { return }
        showVerifyWordsViewController(in: navigationController, with: words, in: flow)
      }
    }
  }

  private func showVerifyWordsViewController(in navigationController: UINavigationController,
                                             with words: [String],
                                             in flow: RecoveryWordsFlow) {
    let viewController = VerifyRecoveryWordsViewController.makeFromStoryboard()
    viewController.recoveryWords = words
    viewController.flow = flow
    assignCoordinationDelegate(to: viewController)
    navigationController.pushViewController(viewController, animated: true)
  }

  func viewController(_ viewController: UIViewController, shouldPromptToSkipWords words: [String]) {
    self.viewController(viewController, didSkipBackingUp: words, flow: .createWallet)
  }
}
