//
//  AppCoordinator+GetBitcoinSuccessViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 10/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: GetBitcoinSuccessViewControllerDelegate {
  func viewControllerRequestedTrackingBitcoinPurchase(_ viewController: GetBitcoinSuccessViewController, transferID: String) {
    viewController.dismiss(animated: true, completion: nil)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .quickPayTrackPurchase(transferID)) else { return }
    openURLExternally(url, completionHandler: nil)
  }
}
