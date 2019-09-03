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
    let url = CoinNinjaUrlFactory.buildUrl(for: .contactUs)!
    parent?.openURL(url, completionHandler: nil)
  }
}
