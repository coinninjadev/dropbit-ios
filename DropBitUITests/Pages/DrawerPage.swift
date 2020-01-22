//
//  DrawerPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DrawerPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .drawer(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapGetBitcoin() -> Self {
    let getBitcoinView = app.cell(withId: .drawer(.getBitcoin))
    getBitcoinView.tap()
    return self
  }

  @discardableResult
  func closeDrawer() -> Self {
    let infoView = app.view(withId: .drawer(.versionInfo))
    infoView.tap()
    return self
  }

}
