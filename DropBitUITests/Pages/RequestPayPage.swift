//
//  RequestPayPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class RequestPayPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .requestPay(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func checkAddressLabelDisplays(expectedAddress: String) -> Self {
    let addressLabel = app.staticTexts(.requestPay(.addressLabel))
    let displayedAddress = addressLabel.label
    XCTAssert(displayedAddress == expectedAddress,
              "The displayed request address (\(displayedAddress)) does not match the expected address \(expectedAddress)")
    return self
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.requestPay(.closeButton), assertionWait: .custom(0.5))
    closeButton.tap()
    return self
  }

  @discardableResult
  func enterAmount(_ amountText: String) -> Self {
    let editAmountButton = app.buttons(.requestPay(.addAmountButton)) //, assertionWait: .custom(1.5)
    editAmountButton.tap()
    let textField = app.textFields(.requestPay(.editAmountTextField))
    textField.typeText(amountText)
    let doneButton = app.buttons["Done"]
    doneButton.tap()
    return self
  }

  @discardableResult
  func createInvoice() -> Self {
    let button = app.buttons(.requestPay(.bottomActionButton))
    button.tap()
    _ = app.image(withId: .requestPay(.qrImage), assertionWait: .custom(3.0))
    return self
  }

}
