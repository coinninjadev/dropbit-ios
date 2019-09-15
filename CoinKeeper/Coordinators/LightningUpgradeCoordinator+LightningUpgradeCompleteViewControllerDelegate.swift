//
//  LightningUpgradeCoordinator+LightningUpgradeCompleteViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 9/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension LightningUpgradeCoordinator: LightningUpgradeCompleteViewControllerDelegate {
  func viewControllerDidSelectGoToWallet(_ viewController: LightningUpgradeCompleteViewController) {
    coordinationDelegate?.coordinatorDidCompleteUpgrade(self)
  }

  func viewControllerDidSelectGetRecoveryWords(_ viewController: LightningUpgradeCompleteViewController) {
    coordinationDelegate?.coordinatorRequestedVerifyUpgradedWords(self)
  }
}
