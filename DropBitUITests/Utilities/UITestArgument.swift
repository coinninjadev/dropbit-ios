//
//  UITestConfig.swift
//  DropBit
//
//  Created by Ben Winters on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// These cases are intended to outline actions that the target app should take on launch.
/// They do not necessarily match persisted values one-to-one.
enum UITestArgument: String {
  case resetPersistence
  case skipGlobalMessageDisplay
  case skipTwitterAuthentication
  case resetForICloudRestore
  case loadMockTransactionHistory
  case uiTestInProgress

  static let prefix = "ui-test-argument-"

  init?(string: String) {
    let rawValue = string.replacingOccurrences(of: UITestArgument.prefix, with: "")
    self.init(rawValue: rawValue)
  }

  var fullArgument: String {
    return UITestArgument.prefix + rawValue
  }

}
