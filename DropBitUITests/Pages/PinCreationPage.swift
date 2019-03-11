//
//  PinCreationPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class PinCreationPage: UITestPage {

  init() {
    super.init(page: .pinCreation(.page))
  }

  /// This method using tap(withNumberOfTaps:, numberOfTouches:) is a bit faster than iterating over an array of digits.
  @discardableResult
  func enterSimplePin(digit: Int, times: Int) -> Self {
    let setPinLabel = app.staticTexts["Set Your PIN"]
    XCTAssert(setPinLabel.exists, "Set pin label does not exist")

    let enterDigitButton = app.buttons["\(digit)"]
    enterDigitButton.tap(withNumberOfTaps: times, numberOfTouches: 1)

    let reenterPinLabel = app.staticTexts["Re-Enter PIN"]
    reenterPinLabel.assertExistence(afterWait: .none, elementDesc: "reenterPinLabel")

    let reenterDigitButton = app.buttons["\(digit)"]
    reenterDigitButton.tap(withNumberOfTaps: times, numberOfTouches: 1)

    return self
  }

  @discardableResult
  func enterPin(_ pin: [Int]) -> Self {
    let setPinLabel = app.staticTexts["Set Your PIN"]
    XCTAssert(setPinLabel.exists, "Set pin label does not exist")

    for digit in pin {
      let digitButton = app.buttons["\(digit)"]
      digitButton.tap()
    }

    let reenterPinLabel = app.staticTexts["Re-Enter PIN"]
    reenterPinLabel.assertExistence(afterWait: .none, elementDesc: "reenterPinLabel")

    for digit in pin {
      let digitButton = app.buttons["\(digit)"]
      digitButton.tap()
    }

    return self
  }

}
