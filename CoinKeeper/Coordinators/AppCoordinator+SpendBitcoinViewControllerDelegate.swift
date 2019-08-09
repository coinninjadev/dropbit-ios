//
//  AppCoordinator+SpendBitcoinViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreLocation

extension AppCoordinator: SpendBitcoinViewControllerDelegate {
  func viewControllerSpendBitcoinAroundMe(_ viewController: SpendBitcoinViewController) {
    analyticsManager.track(event: .spendOnAroundMe, with: nil)
    permissionManager.requestPermission(for: .location) { (status) in
      switch status {
      case .authorized, .notDetermined:
        guard let coordinate = CLLocationManager().location?.coordinate,
          let url = CoinNinjaUrlFactory.buildUrl(for: .spendBitcoinAroundMe(coordinate)) else { return }
        self.openURL(url, completionHandler: nil)
      case .denied, .disabled:
        let description = "To use the location-based services for finding ways of spending Bitcoin near you," +
        " please enable location services in the iOS Settings app."
        let controller = self.alertManager.defaultAlert(withTitle: "Location Services not enabled", description: description)
        self.navigationController.topViewController()?.present(controller, animated: true, completion: nil)
      }
    }
  }

  func viewControllerSpendBitcoinOnline(_ viewController: SpendBitcoinViewController) {
    analyticsManager.track(event: .spendOnOnline, with: nil)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .spendBitcoinOnline) else { return }
    openURLExternally(url, completionHandler: nil)
  }

  func viewControllerSpendGiftCards(_ viewController: SpendBitcoinViewController) {
    analyticsManager.track(event: .spendOnGiftCards, with: nil)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .spendBitcoinGiftCards) else { return }
    openURLExternally(url, completionHandler: nil)
  }
}
