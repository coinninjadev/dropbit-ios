//
//  ImportWalletUITests.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class ImportWalletUITests: UITestCase, UITestRecoverWordBackupAutomatable {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication])
    app.launch()
  }

  /*
  func testRestoringWalletShowsFirstAddress() {
    let recoveryWords = UITestHelpers.recoverOnlyWords()
    let firstAddress = UITestHelpers.recoverOnlyWordsFirstAddress

    addSystemAlertMonitor()

    StartPage()
      .tapRestore()

    PinCreationPage()
      .enterSimplePin(digit: 1, times: 6)

    RestoreWalletPage()
      .enterWords(recoveryWords)

    SuccessFailPage().checkWalletRecoverySucceeded()
      .tapGoToWallet()

    DeviceVerificationPage()
      .tapSkip()

    PushInfoPage()?.dismiss()

    WalletOverviewPage()
      .tapRequest()

    RequestPayPage()
      .checkAddressLabelDisplays(expectedAddress: firstAddress)
  }
 */

  func testRestoringWalletWithUppercaseWordsSucceeds() {
    let recoveryWords = UITestHelpers.recoverOnlyWords().map { $0.uppercased() }

    addSystemAlertMonitor()

    StartPage().tapRestore()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)
//    SuccessFailPage().checkWalletRecoverySucceeded()
  }

  func testRestoringLegacyDeactivatedWalletPromptsUserToStartOver() {
    let recoveryWords = UITestHelpers.recoverOnlyLegacyDeactivatedWords()

    addSystemAlertMonitor()

    StartPage().tapRestore()
    PinCreationPage().enterSimplePin(digit: 2, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)

    let title = "You have entered recovery words from a legacy DropBit wallet. We are upgrading all wallets to " +
    "a new version of DropBit for enhanced security, lower transaction fees, and Lightning support. Please enter " +
    "the new recovery words you were given upon upgrading, or create a new wallet."
    let predicate = NSPredicate(format: "label == %@", title)
    let alertLabel = app.staticTexts.containing(predicate).firstMatch
    let alertLabelExists = alertLabel.waitForExistence(timeout: 1.0)
    XCTAssert(alertLabelExists)

    app.buttons["Start Over"].tap()

    StartPage().tapNewWallet()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()

    DropBitMePage()?.tapClose()

    let backupHeader = backupWalletWarningHeader()
    backupHeader.tap()

    performBackup()
  }

  func testRestoringLegacyWalletNeedingUpgradeStartsUpgrade() {
    let recoveryWords = UITestHelpers.recoverOnlyLegacyWords()

    addSystemAlertMonitor()

    StartPage().tapRestore()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)

    LightningUpgradeStartPage().tapUpgradeNow()
  }
}
