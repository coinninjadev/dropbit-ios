//
//  NewWalletUITests.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class NewWalletUITests: UITestCase, UITestRecoverWordBackupAutomatable {

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

    WalletOverviewPage().tapMenu()

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

}
