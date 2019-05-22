//
//  NewWalletUITests.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class NewWalletUITests: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipGlobalMessageDisplay, .skipTwitterAuthentication])
    app.launch()
  }

  func testSkippingRecoveryWordsShowsBadgeInDrawer() {
    StartPage().tapNewWallet()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()

    let toastLabel = bannerToast()
    toastLabel.swipeUp()

    TransactionHistoryPage().tapMenu()

    let backupWalletCell = app.staticTexts["Back Up Wallet"]
    let backupWalletCellExists = backupWalletCell.waitForExistence(timeout: 1.0)
    XCTAssert(backupWalletCellExists)

    backupWalletCell.tap()

    performBackup()
  }

  func testSkippingRecoveryWordsBannerIsActionable() {
    StartPage().tapNewWallet()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()

    let toastLabel = bannerToast()
    toastLabel.tap()

    performBackup()
  }

  private func performBackup() {
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
    TransactionHistoryPage().tapMenu()
    let backupWalletCell2 = app.staticTexts["Back Up Wallet"]
    let backupWalletCell2Exists = backupWalletCell2.waitForExistence(timeout: 1.0)
    XCTAssertFalse(backupWalletCell2Exists)
  }

  private func bannerToast() -> XCUIElement {
    let title = "Remember to backup your wallet to ensure your Bitcoin is secure in case your phone is ever lost or stolen. Tap here to backup now."
    let predicate = NSPredicate(format: "label == %@", title)

    let toastLabel = app.staticTexts.containing(predicate).firstMatch
    let toastExists = toastLabel.waitForExistence(timeout: 2.0)
    XCTAssert(toastExists)
    return toastLabel
  }
}
