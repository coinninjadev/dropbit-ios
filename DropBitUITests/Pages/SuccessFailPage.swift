//
//  SuccessFailPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class SuccessFailPage: UITestPage {

  init() {
    super.init(page: .successFail(.page))
  }

  override var rootElement: XCUIElement {
    return app.viewController(withId: .successFail(.page))
  }

  @discardableResult
  func checkWalletRecoverySucceeded() -> Self {
    let successLabel = app.staticTexts["WALLET RECOVERED"]
    successLabel.assertExistence(afterWait: .none, elementDesc: "wallet recovered success label")
    return self
  }

  @discardableResult
  func tapGoToWallet() -> Self {
    let goToWalletButton = app.buttons(.successFail(.actionButton))
    goToWalletButton.tap()
    return self
  }

}
