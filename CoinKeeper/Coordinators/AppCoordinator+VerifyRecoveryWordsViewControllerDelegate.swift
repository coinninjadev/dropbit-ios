//
//  AppCoordinator+VerifyRecoveryWordsViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: VerifyRecoveryWordsViewControllerDelegate {

  func viewController(_ viewController: UIViewController, didSkipBackingUpWords words: [String], in flow: RecoveryWordsFlow) {
    self.viewController(viewController, didSkipBackingUp: words, flow: flow)
  }

  func viewController(_ viewController: UIViewController, didSuccessfullyVerifyWords words: [String], in flow: RecoveryWordsFlow) {
    saveSuccessfulWords(words: words, isBackedUp: true, flow: flow)
      .done(on: .main) {
        self.analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: true))
        self.analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: true))
        self.badgeManager.publishBadgeUpdate()
        self.continueNavigation(with: viewController, for: flow)
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
    let okAction = AlertActionConfiguration(title: "Ok", style: .default) { [weak self] in
      viewController.navigationController?.popViewController(animated: true)
      self?.viewControllerResetRecoveryWords(viewController)
    }
    let configs = [okAction]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: configs)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  private func viewControllerResetRecoveryWords(_ viewController: UIViewController) {
    viewController.navigationController?.viewControllers
      .compactMap { $0 as? CreateRecoveryWordsViewController }
      .first
      .map { $0.reviewAllRecoveryWords() }
  }
}
