//
//  TransactionDetailCellPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/26/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class TransactionDetailCellPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .transactionDetailCell(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.transactionDetailCell(.closeButton))
    closeButton.assertExistence(afterWait: .none, elementDesc: "closeButton")
    closeButton.tap()
    return self
  }
}

