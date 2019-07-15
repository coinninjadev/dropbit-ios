//
//  MemoEntryUITests.swift
//  DropBitUITests
//
//  Created by BJ Miller on 12/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class MemoEntryUITests: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication])
    app.launch()
  }

  func testMemoEntryHasMaxCharacterLimit() {
    let recoveryWords = UITestHelpers.recoverOnlyWords()
    let expectedMemo = "i am a memo"

    StartPage().tapRestore()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)
    SuccessFailPage().checkWalletRecoverySucceeded().tapGoToWallet()
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()
    WalletOverviewPage().tapSend()
    SendPaymentPage().tapMemoButton()

    MemoEntryPage()
      .enterText("aaaaaaaaaa", count: 13)
      .enterText("a")
      .assertCharacterLimit(of: 130)
      .clearText()
      .enterText(expectedMemo)
      .tapToDismiss()

    SendPaymentPage().assertMemoLabelText(equals: expectedMemo)
  }
}
