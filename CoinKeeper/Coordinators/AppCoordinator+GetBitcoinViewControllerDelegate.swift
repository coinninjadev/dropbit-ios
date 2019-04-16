//
//  AppCoordinator+GetBitcoinViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreLocation

extension AppCoordinator: GetBitcoinViewControllerDelegate {
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController) {
    analyticsManager.track(event: .buyBitcoinAtATM, with: nil)
    permissionManager.requestPermission(for: .location) { (status) in
      switch status {
      case .authorized, .notDetermined:
        guard let coordinate = CLLocationManager().location?.coordinate,
          let url = CoinNinjaUrlFactory.buildUrl(for: .buyAtATM(coordinate)) else { return }
        self.openURL(url, completionHandler: nil)
      case .denied, .disabled:
        let description = "To use the location-based services of finding Bitcoin ATMs near you," +
        " please enable location services in the iOS Settings app."
        let controller = self.alertManager.defaultAlert(withTitle: "Location Services not enabled", description: description)
        self.navigationController.topViewController()?.present(controller, animated: true, completion: nil)
      }
    }
  }

  func viewControllerBuyWithCreditCard(_ viewController: GetBitcoinViewController) {
    analyticsManager.track(event: .buyBitcoinWithCreditCard, with: nil)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyWithCreditCard) else { return }
    openURL(url, completionHandler: nil)
  }

  func viewControllerBuyWithGiftCard(_ viewController: GetBitcoinViewController) {
    analyticsManager.track(event: .buyBitcoinWithGiftCard, with: nil)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyGiftCards) else { return }
    openURL(url, completionHandler: nil)
  }
}
