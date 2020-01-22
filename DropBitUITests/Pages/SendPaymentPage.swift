//
//  SendPaymentPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 12/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class SendPaymentPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .sendPayment(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapMemoButton() -> Self {
    let memoLabel = app.staticTexts(.sendPayment(.memoLabel))
    memoLabel.assertExistence(afterWait: .none, elementDesc: "memoLabel")
    memoLabel.tap()
    return self
  }

  @discardableResult
  func assertMemoLabelText(equals expectedText: String) -> Self {
    let memoLabel = app.staticTexts[expectedText]
    memoLabel.assertExistence(afterWait: .none, elementDesc: "memoLabel")
    return self
  }

}
