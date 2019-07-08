//
//  URLOpener.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol URLOpener: AnyObject {
  func openURL(_ url: URL, completionHandler completion: (() -> Void)?)
  func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?)
}

protocol ViewControllerURLDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL)
}

extension ViewControllerURLDelegate {
  func viewController(_ viewController: UIViewController,
                      didRequestOpenURL coinNinjaURL: CoinNinjaUrlFactory.CoinNinjaURL) {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: coinNinjaURL) else { return }
    self.viewController(viewController, didRequestOpenURL: url)
  }
}
