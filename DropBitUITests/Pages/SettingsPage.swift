//
//  SettingsPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class SettingsPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .settings(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.settings(.closeButton))
    closeButton.tap()
    return self
  }

}
