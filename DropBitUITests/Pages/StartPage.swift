//
//  StartPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class StartPage: UITestPage {

  init() {
    super.init(page: .start(.page))
  }

  @discardableResult
  func tapRestore() -> Self {
    let restoreButton = app.buttons["Restore from backup"]
    restoreButton.assertExistence(afterWait: .none, elementDesc: "restoreButton")
    restoreButton.tap()
    return self
  }

  @discardableResult
  func tapNewWallet() -> Self {
    let button = app.buttons["NEW WALLET"]
    button.assertExistence(afterWait: .none, elementDesc: "newWalletButton")
    button.tap()
    return self
  }

}
