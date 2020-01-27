//
//  EarnPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class EarnPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .earn(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.earn(.closeButton), assertionWait: .custom(0.5))
    closeButton.tap()
    return self
  }

}
