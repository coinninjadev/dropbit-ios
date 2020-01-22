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

}
