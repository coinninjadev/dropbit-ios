//
//  LightningUpgradeStartPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class LightningUpgradeStartPage: UITestPage {

  init() {
    super.init(page: .lightningUpgradeStart(.page))
  }

  @discardableResult
  func tapUpgradeNow() -> Self {
    let upgradeButton = app.buttons(.lightningUpgradeStart(.startUpgradeButton))
    upgradeButton.tap()
    return self
  }
}
