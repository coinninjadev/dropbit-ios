//
//  AppCoordinator+RecoveryWordsIntroViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: RecoveryWordsIntroViewControllerDelegate {
  func viewController(_ viewController: UIViewController, didChooseToBackupWords words: [String], in flow: RecoveryWordsFlow) {
    switch flow {
    case .createWallet:
      let viewController = CreateRecoveryWordsViewController.makeFromStoryboard()
      viewController.recoveryWords = words
      assignCoordinationDelegate(to: viewController)
      navigationController.pushViewController(viewController, animated: true)
    case .settings:
      viewController.dismiss(animated: false, completion: nil)
      navigationController.present(createPinEntryViewControllerForRecoveryWords(words), animated: true)
    }
  }

  func viewController(_ viewController: UIViewController, didSkipWords words: [String]) {
    self.viewController(viewController, didSkipBackingUp: words, flow: .createWallet)
  }
}
