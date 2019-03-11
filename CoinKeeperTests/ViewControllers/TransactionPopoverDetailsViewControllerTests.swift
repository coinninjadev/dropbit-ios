//
//  TransactionPopoverDetailsViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitch on 12/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class TransactionPopoverDetailsViewControllerTests: XCTestCase {
  var sut: TransactionPopoverDetailsViewController!

  override func setUp() {
    super.setUp()
    self.sut = TransactionPopoverDetailsViewController.makeFromStoryboard()
    _ = sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.containerView, "containerView should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(self.sut.whenSentTitleLabel, "whenSentTitleLabel should be connected")
    XCTAssertNotNil(self.sut.whenSentAmountLabel, "whenSentAmountLabel should be connected")
    XCTAssertNotNil(self.sut.networkFeeTitleLabel, "networkFeeTitleLabel should be connected")
    XCTAssertNotNil(self.sut.networkFeeAmountLabel, "networkFeeAmountLabel should be connected")
    XCTAssertNotNil(self.sut.confirmationsTitleLabel, "confirmationsTitleLabel should be connected")
    XCTAssertNotNil(self.sut.confirmationsAmountLabel, "confirmationsAmountLabel should be connected")
    XCTAssertNotNil(self.sut.txidLabel, "addressLabel should be connected")
    XCTAssertNotNil(self.sut.seeTransactionDetailsButton, "seeTransactionDetailsButton should be connected")
    XCTAssertNotNil(self.sut.shareTransactionButton, "shareTransactionButton should be connected")
    XCTAssertNotNil(self.sut.questionMarkButton, "questionMarkButton should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.containerViewCenterYConstraint, "containerViewCenterYConstraint should be connected")
  }
}
