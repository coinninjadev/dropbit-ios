//
//  CalculatorPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class CalculatorPage: UITestPage {

  init() {
    super.init(page: .calculator(.page))
  }

  @discardableResult
  func tapRequest() -> Self {
    let receiveButton = app.buttons(.calculator(.receiveButton))
    receiveButton.assertExistence(afterWait: .none, elementDesc: "receiveButton")
    receiveButton.tap()
    return self
  }

  @discardableResult
  func tapPay() -> Self {
    let sendButton = app.buttons(.calculator(.sendButton))
    sendButton.assertExistence(afterWait: .none, elementDesc: "sendButton")
    sendButton.tap()
    return self
  }

  @discardableResult
  func tapBalance() -> Self {
    let balanceView = app.view(withId: .calculator(.balanceView))
    balanceView.assertExistence(afterWait: .none, elementDesc: "balanceView")
    balanceView.tap()
    return self
  }
}
