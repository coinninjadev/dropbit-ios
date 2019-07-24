//
//  WalletOverviewPage.swift
//  DropBitUITests
//
//  Created by Mitchell Malleo on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class WalletOverviewPage: UITestPage {
  
  init() {
    super.init(page: .walletOverview(.page))
  }
  
  @discardableResult
  func tapTutorialButton() -> Self {
    let tutorialButton = app.buttons(.walletOverview(.tutorialButton))
    tutorialButton.assertExistence(afterWait: .default, elementDesc: "learnAboutBitcoinButton")
    tutorialButton.tap()
    return self
  }
  
  @discardableResult
  func tapMenu() -> Self {
    let menuButton = app.buttons(.walletOverview(.menu))
    menuButton.assertExistence(afterWait: .none, elementDesc: "menuButton")
    menuButton.tap()
    return self
  }
  
  @discardableResult
  func tapRequest() -> Self {
    let receiveButton = app.buttons(.walletOverview(.receiveButton))
    receiveButton.assertExistence(afterWait: .none, elementDesc: "receiveButton")
    receiveButton.tap()
    return self
  }
  
  @discardableResult
  func tapSend() -> Self {
    let sendButton = app.buttons(.walletOverview(.sendButton))
    sendButton.assertExistence(afterWait: .none, elementDesc: "sendButton")
    sendButton.tap()
    return self
  }
  
  @discardableResult
  func tapBalance() -> Self {
    let balanceView = app.view(withId: .walletOverview(.balanceView))
    balanceView.assertExistence(afterWait: .none, elementDesc: "balanceView")
    balanceView.tap()
    return self
  }
}
