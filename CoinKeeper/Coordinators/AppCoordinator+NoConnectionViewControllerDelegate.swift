//
//  AppCoordinator+NoConnectionViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 2/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
extension AppCoordinator: NoConnectionViewControllerDelegate {
  func viewControllerDidRequestRetry(_ viewController: UIViewController, completion: @escaping () -> Void) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    networkManager.walletCheckIn()
      .done { _ in
        self.connectionManager.setAPIUnreachable(false)
        viewController.dismiss(animated: true) {
          completion()
        }
      }
      .catch { _ in self.connectionManager.setAPIUnreachable(true) }
      .finally(on: .main) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        completion()
      }
  }
}
