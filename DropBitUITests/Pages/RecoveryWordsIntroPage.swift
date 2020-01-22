//
//  RecoveryWordsIntroPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class RecoveryWordsIntroPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .recoveryWordsIntro(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapBackup() -> Self {
    let backupButton = app.buttons["WRITE DOWN WORDS + BACK UP"]
    backupButton.assertExistence(afterWait: .none, elementDesc: "backupButton")
    backupButton.forceTap()
    return self
  }

  @discardableResult
  func tapSkip() -> Self {
    let skipButton = app.buttons["SKIP AND BACK UP LATER"]
    skipButton.assertExistence(afterWait: .none, elementDesc: "skipButton")
    skipButton.forceTap()
    return self
  }
}

extension XCUIElement {
  func forceTap() {
    if self.isHittable {
      self.tap()
    } else {
      let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
      coordinate.tap()
    }
  }
}
