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

  func viewControllerDidPressShareButton(_ viewController: UIViewController) {
    let context = persistenceManager.viewContext
    guard let walletID = persistenceManager.brokers.wallet.walletId(in: context) else { return }
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .trackReferralStatus(walletID: walletID)) else { return }
    openURL(url, completionHandler: nil)
  }

  func viewControllerRestrictionsButtonWasTouched(_ viewController: UIViewController) {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .restrictions) else { return }
    openURL(url, completionHandler: nil)
  }
}
