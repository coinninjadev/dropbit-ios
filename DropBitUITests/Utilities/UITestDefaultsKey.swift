//
//  UITestDefaultsKey.swift
//  CoinKeeper
//
//  Created by Ben Winters on 11/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// These keys can be used to write values to the main app's UserDefaults for use during UI tests.
enum UITestDefaultsKey: String {
  case seedWords

  static let prefix = "uiTestDefaultsKey-"

  init?(string: String) {
    let rawValue = string.replacingOccurrences(of: UITestDefaultsKey.prefix, with: "")
    self.init(rawValue: rawValue)
  }

  var fullKey: String {
    return UITestDefaultsKey.prefix + rawValue
  }

}
