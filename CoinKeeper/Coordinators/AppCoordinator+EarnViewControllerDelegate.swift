//
//  AppCoordinator+EarnViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: EarnViewControllerDelegate {

  func viewControllerDidPressShareButton(_ viewController: UIViewController, referralLink: String) {
    let shareSheet = UIActivityViewController(activityItems: [referralLink], applicationActivities: nil)
    shareSheet.excludedActivityTypes = UIActivity.standardExcludedTypes

    self.navigationController.topViewController()?.present(shareSheet, animated: true, completion: nil)
  }

  func viewControllerRestrictionsButtonWasTouched(_ viewController: UIViewController) {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .restrictions) else { return }
    openURL(url, completionHandler: nil)
  }
}
