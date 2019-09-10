//
//  PinEntryPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class PinEntryPage: UITestPage {

  init() {
    super.init(page: .pinEntry(.page))
  }

  @discardableResult
  func enterSimplePin(digit: Int, times: Int) -> Self {
    let infoLabel = app.staticTexts["Enter PIN to unlock recovery words"]
    XCTAssert(infoLabel.exists, "info label should exist")

    let enterDigitButton = app.buttons["\(digit)"]
    enterDigitButton.tap(withNumberOfTaps: times, numberOfTouches: 1)

    return self
  }
}
