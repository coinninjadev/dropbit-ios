//
//  PushInfoPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class PushInfoPage: UITestPage {

  init?() {
    super.init(optionalPage: .actionableAlert(.page))
  }

  func dismiss() {
    let dismissPushInfoButton = self.app.buttons(.actionableAlert(.actionButton))
    dismissPushInfoButton.tap()
  }

}
