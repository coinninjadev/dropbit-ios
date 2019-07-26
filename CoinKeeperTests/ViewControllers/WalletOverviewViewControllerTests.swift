//
//  WalletOverviewViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import XCTest

class WalletOverviewViewControllerTests: XCTestCase {
  var sut: WalletOverviewViewController!

  override func setUp() {
    super.setUp()
    sut = WalletOverviewViewController.makeFromStoryboard()
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.balanceContainer, "balanceContainer should be connected")
    XCTAssertNotNil(sut.walletToggleView, "walletToggleView should be connected")
    XCTAssertNotNil(sut.sendReceiveActionView, "sendReceiveActionView should be connected")
    XCTAssertNotNil(sut.tooltipButton, "tooltipButton should be connected")
  }
}
