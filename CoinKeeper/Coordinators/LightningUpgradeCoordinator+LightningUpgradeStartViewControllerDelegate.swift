//
//  LightningUpgradeCoordinator+LightningUpgradeStartViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension LightningUpgradeCoordinator: LightningUpgradeStartViewControllerDelegate {
  func viewControllerRequestedShowLightningUpgradeInfo(_ viewController: LightningUpgradeStartViewController) {
    let url = CoinNinjaUrlFactory.buildUrl(for: .lightningUpgrade)!
    parent.openURL(url, completionHandler: nil)
  }

  func viewControllerRequestedUpgradeAuthentication(_ viewController: LightningUpgradeStartViewController, completion: @escaping CKCompletion) {
    let controller = parent.createPinEntryViewControllerForAppOpen { [weak self] in
      if let controller = self?.parent.navigationController.topViewController() as? PinEntryViewController {
        controller.dismiss(animated: true, completion: nil)
      }
      completion()
    }

    parent.navigationController.topViewController()?.show(controller, sender: nil)
  }
}
