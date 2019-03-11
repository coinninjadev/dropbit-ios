//
//  RecoveryWordsIntroPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class RecoveryWordsIntroPage: UITestPage {

  init() {
    super.init(page: .recoveryWordsIntro(.page))
  }

  @discardableResult
  func tapBackup() -> Self {
    let backupButton = app.buttons["WRITE DOWN WORDS + BACK UP"]
    backupButton.assertExistence(afterWait: .none, elementDesc: "backupButton")
    backupButton.tap()
    return self
  }

  @discardableResult
  func tapSkip() -> Self {
    let skipButton = app.buttons["SKIP AND BACK UP LATER"]
    skipButton.assertExistence(afterWait: .none, elementDesc: "skipButton")
    skipButton.tap()
    return self
  }
}
