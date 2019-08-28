//
//  AppCoordinator+VerifyRecoveryWordsViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: VerifyRecoveryWordsViewControllerDelegate {

  func viewController(_ viewController: UIViewController, didSkipBackingUpWords words: [String]) {
    let backupNowConfig = AlertActionConfiguration(title: "Back up now", style: .cancel, action: nil)
    let skipConfig = AlertActionConfiguration(title: "OK, skip", style: .default) {
      viewController.dismiss(animated: true, completion: nil)
    }
    let title = "You will have restricted use of the DropBit features until your wallet" +
    " is backed up. Please backup as soon as you are able."
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: [backupNowConfig, skipConfig])
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerDidSuccessfullyVerifyWords(_ viewController: UIViewController) {
    self.persistenceManager.keychainManager.storeWalletWordsBackedUp(true)
      .done(on: .main) {
        self.analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: true))
        self.analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: true))
        self.badgeManager.publishBadgeUpdate()
        viewController.dismiss(animated: true, completion: nil)
      }.cauterize()
  }

  func viewControllerFailedWordVerification(_ viewController: UIViewController) {
    let title = "\nIncorrect word. Are you sure you have your words?\n"
    let tryAgainConfig = AlertActionConfiguration(title: "Try Again", style: .cancel, action: nil)
    let seeWordsConfig = AlertActionConfiguration(title: "See Words", style: .default) { [weak self] in
      viewController.navigationController?.popViewController(animated: true)
      self?.viewControllerResetRecoveryWords(viewController)
    }
    let configs = [seeWordsConfig, tryAgainConfig]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: configs)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerWordVerificationMaxFailuresAttempted(_ viewController: UIViewController) {
    let title = "\n Too many attempts. Please review your recovery words and ensure you write them down.\n"
    let okAction = AlertActionConfiguration(title: "OK", style: .default) { [weak self] in
      viewController.navigationController?.popViewController(animated: true)
      self?.viewControllerResetRecoveryWords(viewController)
    }
    let configs = [okAction]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: configs)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  private func viewControllerResetRecoveryWords(_ viewController: UIViewController) {
    viewController.navigationController?.viewControllers
      .compactMap { $0 as? BackupRecoveryWordsViewController }
      .first
      .map { $0.reviewAllRecoveryWords() }
  }
}
