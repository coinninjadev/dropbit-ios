//
//  DropBitUIDatabaseTests.swift
//  DropBitUIDatabaseTests
//
//  Created by BJ Miller on 8/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DropBitUIDatabaseTests: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetForICloudRestore, .skipGlobalMessageDisplay, .skipTwitterAuthentication])
    app.launch()
  }

  /*
  func testRestoreFromICloudPromptsUser() {

    let recoveryWords = UITestHelpers.recoverOnlyWords()
    let firstAddress = UITestHelpers.recoverOnlyWordsFirstAddress

    let title = "It looks like you have restored from a backup. Please enter your 12 recovery words to restore your wallet."
    let predicate = NSPredicate(format: "label == %@", title)

    let toastLabel = app.staticTexts.containing(predicate).firstMatch
    let toastExists = toastLabel.waitForExistence(timeout: 2.0)
    XCTAssert(toastExists)

    app.buttons["RESTORE NOW"].tap()

    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)
    SuccessFailPage()
      .checkWalletRecoverySucceeded()
      .tapGoToWallet()
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()
    WalletOverviewPage().tapRequest()
    RequestPayPage().checkAddressLabelDisplays(expectedAddress: firstAddress)

  }
  */

}
