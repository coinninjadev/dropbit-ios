//
//  AppCoordinator+ShareTransactionViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: ShareTransactionViewControllerDelegate {

  func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController) {
    viewController.dismiss(animated: true) {
      // get memo for latest transaction and create tweet body
      let message = "Hello world!"

      var comps = URLComponents()
      comps.scheme = "twitter"
      comps.path = "post"
      comps.queryItems = [URLQueryItem(name: "message", value: message)]
      if let url = comps.url {
        print("Will open Twitter: \(url.absoluteString)")
        self.openURL(url, completionHandler: nil)
      } else {
        print("Failed to open Twitter")
      }
    }
  }
}
