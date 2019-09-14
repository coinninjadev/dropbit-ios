//
//  SwiftMessagesBannerPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class SwiftMessagesBannerPage: UITestPage {

  init() {
    super.init(page: .bannerMessage(.page))
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.bannerMessage(.close))
    closeButton.assertExistence(afterWait: .custom(5.0), elementDesc: "closeButton")
    closeButton.tap()
    return self
  }
}
