//
//  SupportPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class SupportPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .support(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.support(.closeButton))
    closeButton.tap()
    return self
  }

}
