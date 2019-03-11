//
//  TransactionHistoryPage.swift
//  DropBitUITests
//
//  Created by Mitch on 1/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionHistoryPage: UITestPage {

  init() {
    super.init(page: .transactionHistory(.page))
  }

  @discardableResult
  func tapTutorialButton() -> Self {
    let receiveButton = app.buttons(.transactionHistory(.tutorialButton))
    receiveButton.assertExistence(afterWait: .none, elementDesc: "learnAboutBitcoinButton")
    receiveButton.tap()
    return self
  }

}
