//
//  ImportWalletUITests.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class ImportWalletUITests: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence])
    app.launch()
  }

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

//    CalculatorPage()
//      .tapRequest()
//
//    RequestPayPage()
//      .checkAddressLabelDisplays(expectedAddress: firstAddress)
  }
}
