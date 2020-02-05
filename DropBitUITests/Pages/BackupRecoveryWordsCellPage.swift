//
//  BackupRecoveryWordsCellPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class BackupRecoveryWordsCellPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .backupRecoveryWordsCell(.page), assertionWait: .default, ifExists: ifExists)
  }

  func recoveryWordString() -> String {
    let wordLabel = app.staticTexts(.backupRecoveryWordsCell(.wordLabel))
    return wordLabel.title
  }

}
