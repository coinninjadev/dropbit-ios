//
//  AppCoordinator+RecoveryWordsIntroViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: RecoveryWordsIntroViewControllerDelegate {
  func viewController(_ viewController: UIViewController, didChooseToBackupWords words: [String]) {
    viewController.dismiss(animated: false, completion: nil)

    let viewModel = RecoveryWordsPinEntryViewModel()

    let successHandler: CompletionHandler = { [unowned self] in
      self.analyticsManager.track(event: .viewWords, with: nil)
      let backupWordsVC = BackupRecoveryWordsViewController.newInstance(withDelegate: self,
                                                                        recoveryWords: words,
                                                                        wordsBackedUp: self.wordsBackedUp)
      self.navigationController.present(CNNavigationController(rootViewController: backupWordsVC), animated: false, completion: nil)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self, viewModel: viewModel, success: successHandler, failure: nil)

    navigationController.present(pinEntryVC, animated: true)
  }

  func viewController(_ viewController: UIViewController, didSkipWords words: [String]) {
    self.viewController(viewController, didSkipBackingUpWords: words)
  }
}
