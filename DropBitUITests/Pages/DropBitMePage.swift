//
//  DropBitMePage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class DropBitMePage: UITestPage {

  init() {
    super.init(page: .dropBitMe(.page))
  }

  @discardableResult
  func tapClose() -> Self {
    let closeButton = app.buttons(.dropBitMe(.close))
    closeButton.tap()
    return self
  }
}
