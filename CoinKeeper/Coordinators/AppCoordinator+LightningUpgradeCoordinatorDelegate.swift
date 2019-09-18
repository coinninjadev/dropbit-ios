//
//  AppCoordinator+LightningUpgradeCoordinatorDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 9/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningUpgradeCoordinatorDelegate {
  func coordinatorWillCompleteUpgrade(_ coordinator: LightningUpgradeCoordinator) {
    launchStateManager.upgradeInProgress = false
    analyticsManager.track(property: MixpanelProperty(key: .lightningUpgradeCompleted, value: true))
    analyticsManager.track(property: MixpanelProperty(key: .walletVersion, value: WalletFlagsVersion.v2.rawValue))
  }

  func coordinatorDidCompleteUpgrade(_ coordinator: LightningUpgradeCoordinator) {
    if let controller = navigationController.topViewController() as? LightningUpgradePageViewController {
      controller.dismiss(animated: true, completion: nil)
    }
    childCoordinatorDidComplete(childCoordinator: coordinator)
    validToStartEnteringApp()
  }

  func coordinatorRequestedVerifyUpgradedWords(_ coordinator: LightningUpgradeCoordinator) {
    if let controller = navigationController.topViewController() as? LightningUpgradePageViewController {
      controller.dismiss(animated: true, completion: nil)
    }
    childCoordinatorDidComplete(childCoordinator: coordinator)
    enterApp()
    showWordRecoveryFlow()
  }
}
