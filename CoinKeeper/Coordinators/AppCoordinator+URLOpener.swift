//
//  AppCoordinator+URLOpener.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import SafariServices

extension AppCoordinator: URLOpener {
  func openURL(_ url: URL, completionHandler completion: (() -> Void)?) {
    let safariController = SFSafariViewController(url: url)
    safariController.modalPresentationStyle = .overFullScreen
    navigationController.topViewController()?.present(safariController, animated: true, completion: completion)
  }

  func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) {
    UIApplication.shared.open(url, options: [:], completionHandler: completion)
  }
}
