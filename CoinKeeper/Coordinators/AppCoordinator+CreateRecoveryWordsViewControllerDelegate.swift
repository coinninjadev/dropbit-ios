//
//  AppCoordinator+BackupRecoveryWordsViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: BackupRecoveryWordsViewControllerDelegate {
  func viewController(_ viewController: UIViewController, didFinishWords words: [String]) {
    switch wordsBackedUp {
    case true:
      viewController.dismiss(animated: true, completion: nil)
    case false:
      guard let navigationController = viewController.navigationController else { return }
      showVerifyWordsViewController(in: navigationController, with: words)
    }
  }

  private func showVerifyWordsViewController(in navigationController: UINavigationController,
                                             with words: [String]) {
    let controller = VerifyRecoveryWordsViewController.newInstance(withDelegate: self, recoveryWords: words)
    navigationController.pushViewController(controller, animated: true)
  }

  func viewController(_ viewController: UIViewController, shouldPromptToSkipWords words: [String]) {
    self.viewController(viewController, didSkipBackingUpWords: words)
  }
}
