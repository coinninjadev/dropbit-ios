//
//  DropBitSnapshot.swift
//  DropBitSnapshot
//
//  Created by Ben Winters on 10/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DropBitSnapshot: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication, .skipGlobalMessageDisplay, .loadMockTransactionHistory])
    setupSnapshot(app)
    app.launch()
  }

  func testTransactionHistoryDetails() {
    StartPage().tapNewWallet()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()
    snapshot("history")
    WalletOverviewPage() //page will be hidden by detail cell
      .tapFirstSummaryCell()
      .swipeDetailCells(count: 15)
  }
  
}
