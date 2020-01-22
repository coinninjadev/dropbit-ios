//
//  VerificationStatusPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class VerificationStatusPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .verificationStatus(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.verificationStatus(.closeButton))
    closeButton.tap()
    return self
  }

}
