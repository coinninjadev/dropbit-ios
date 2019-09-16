//
//  UITestRecoverWordBackupAutomatable.swift
//  DropBitUITests
//
//  Created by BJ Miller on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import XCTest

protocol UITestRecoverWordBackupAutomatable: AnyObject {
  var app: XCUIApplication { get }
}

extension UITestRecoverWordBackupAutomatable {

  func performBackup() {
    RecoveryWordsIntroPage().tapBackup()

    PinEntryPage().enterSimplePin(digit: 1, times: 6)

    // discover recovery words
    var words: [String] = []
    for index in (0..<12) {
      let word = app.staticTexts(.backupRecoveryWordsCell(.wordLabel), assertionWait: .custom(1.0)).label
      words.append(word)
      let buttonTitle = index == 11 ? "VERIFY" : "NEXT"
      app.buttons[buttonTitle].tap()
    }

    // verify words
    2.times {
      // get the label
      let currentIndexText = app.staticTexts(.verifyRecoveryWordsCell(.currentIndexLabel), assertionWait: .custom(1.0))
        .label
        .split(separator: " ")
        .last
        .map { String($0) } ?? ""

      // parse the human-readable integer, then subtract 1
      guard let humanIndex = Int(currentIndexText) else {
        XCTFail("could not find and convert current index")
        return
      }
      let currentIndex = humanIndex - 1

      // get word at index
      let currentWord = words[currentIndex]

      // find button from word
      let button = app.buttons[currentWord]

      // tap button
      button.tap()
    }

    // verify backup wallet is gone
    WalletOverviewPage().tapMenu()
    let backupWalletCell2 = app.staticTexts["Back Up Wallet"]
    let backupWalletCell2Exists = backupWalletCell2.waitForExistence(timeout: 1.0)
    XCTAssertFalse(backupWalletCell2Exists)
  }

  func backupWalletWarningHeader() -> XCUIElement {
    let title = "Don't forget to backup your wallet"
    let predicate = NSPredicate(format: "label == %@", title)

    let header = app.staticTexts.containing(predicate).firstMatch
    let headerExists = header.waitForExistence(timeout: 2.0)
    XCTAssert(headerExists)
    return header
  }

}
