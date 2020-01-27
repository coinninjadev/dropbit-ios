//
//  DeviceVerificationPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DeviceVerificationPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .deviceVerification(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapSkip() -> Self {
    let skipButton = app.buttons(.deviceVerification(.skipButton))
    skipButton.tap()
    return self
  }

}
