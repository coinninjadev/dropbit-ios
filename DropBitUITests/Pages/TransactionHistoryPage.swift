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
    let tutorialButton = app.buttons(.transactionHistory(.tutorialButton))
    tutorialButton.assertExistence(afterWait: .default, elementDesc: "learnAboutBitcoinButton")
    tutorialButton.tap()
    return self
  }

  @discardableResult
  func tapMenu() -> Self {
    let menuButton = app.buttons(.transactionHistory(.menu))
    menuButton.assertExistence(afterWait: .none, elementDesc: "menuButton")
    menuButton.tap()
    return self
  }

  @discardableResult
  func tapRequest() -> Self {
    let receiveButton = app.buttons(.transactionHistory(.receiveButton))
    receiveButton.assertExistence(afterWait: .none, elementDesc: "receiveButton")
    receiveButton.tap()
    return self
  }

  @discardableResult
  func tapSend() -> Self {
    let sendButton = app.buttons(.transactionHistory(.sendButton))
    sendButton.assertExistence(afterWait: .none, elementDesc: "sendButton")
    sendButton.tap()
    return self
  }

  @discardableResult
  func tapBalance() -> Self {
    let balanceView = app.view(withId: .transactionHistory(.balanceView))
    balanceView.assertExistence(afterWait: .none, elementDesc: "balanceView")
    balanceView.tap()
    return self
  }

}
