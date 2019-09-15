//
//  AppCoordinator+TwitterTweetingDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: TwitterTweetingDelegate {

  func openTwitterURL(withMessage message: String) {
    var comps = URLComponents()
    comps.scheme = "twitter"
    comps.host = "post"
    comps.queryItems = [URLQueryItem(name: "message", value: message)]
    if let url = comps.url {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      log.error("Failed to create Twitter URL from components")
    }
  }
}
