//
//  DropBitMePage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class DropBitMePage: UITestPage {

  init?() {
    super.init(optionalPage: .dropBitMe(.page))
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.dropBitMe(.close))
    closeButton.assertExistence(afterWait: .custom(5.0), elementDesc: "closeButton")
    closeButton.tap()
    return self
  }
}
