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
    closeButton.tap()
    return self
  }
}
