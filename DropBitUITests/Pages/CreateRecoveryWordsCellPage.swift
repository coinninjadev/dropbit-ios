//
//  CreateRecoveryWordsCellPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class CreateRecoveryWordsCellPage: UITestPage {

  init() {
    super.init(page: .createRecoveryWordsCell(.page))
  }

  func recoveryWordString() -> String {
    let wordLabel = app.staticTexts(.createRecoveryWordsCell(.wordLabel))
    return wordLabel.title
  }

}
