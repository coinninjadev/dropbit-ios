//
//  TransactionHistoryViewControllerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class TransactionHistoryViewControllerTests: XCTestCase {
  var sut: TransactionHistoryViewController!
  var stack: InMemoryCoreDataStack!

  override func setUp() {
    super.setUp()
    stack = InMemoryCoreDataStack()
    sut = TransactionHistoryViewController.makeFromStoryboard()
    sut.context = self.stack.context
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
    stack = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.summaryCollectionView, "summaryCollectionView should be connected")
    XCTAssertNotNil(sut.transactionHistoryNoBalanceView, "transactionHistoryNoBalanceView should be connected")
    XCTAssertNotNil(sut.transactionHistoryWithBalanceView, "transactionHistoryWithBalanceView should be connected")
    XCTAssertNotNil(sut.sendReceiveActionView, "sendReceiveActionView should be connected")
    XCTAssertNotNil(sut.refreshView, "refreshView should be connected")
    XCTAssertNotNil(sut.refreshViewTopConstraint, "refreshViewTopConstraint should be connected")
    XCTAssertNotNil(sut.sendReceiveActionViewBottomConstraint, "sendReceiveActionViewBottomConstraint should be connected")
    XCTAssertNotNil(sut.sendReceiveActionView, "sendReceiveActionView should be connected")
    XCTAssertNotNil(sut.gradientBlurView, "gradientBlurView should be connected")
  }

  // MARK: no transactions
  func testNoTransactionsShowsNoTransactionsViewAndHidesSummaryCollectionView() {
    sut.summaryCollectionView.reloadData()
    XCTAssertFalse(sut.transactionHistoryNoBalanceView.isHidden, "noTransactionsView should be visible when no transactions are in context")
  }
}
