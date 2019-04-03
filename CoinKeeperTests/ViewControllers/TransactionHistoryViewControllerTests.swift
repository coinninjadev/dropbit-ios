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
    self.stack = InMemoryCoreDataStack()
    self.sut = TransactionHistoryViewController.makeFromStoryboard()
    self.sut.context = self.stack.context
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    self.stack = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.balanceContainer, "balanceContainer should be connected")
    XCTAssertNotNil(self.sut.summaryCollectionView, "summaryCollectionView should be connected")
    XCTAssertNotNil(self.sut.detailCollectionView, "detailCollectionView should be connected")
    XCTAssertNotNil(self.sut.detailCollectionViewTopConstraint, "detailCollectionViewTopConstraint should be connected")
    XCTAssertNotNil(self.sut.noTransactionsView, "noTransactionsView should be connected")
    XCTAssertNotNil(self.sut.collectionViews, "collectionViews outlet collection should be connected")
    XCTAssertNotNil(self.sut.sendReceiveActionView, "sendReceiveActionView should be connected")
  }

  // MARK: no transactions
  func testNoTransactionsShowsNoTransactionsViewAndHidesSummaryCollectionView() {
    sut.summaryCollectionView.reloadData()
    XCTAssertFalse(sut.noTransactionsView.isHidden, "noTransactionsView should be visible when no transactions are in context")
    XCTAssertTrue(sut.summaryCollectionView.isHidden, "summaryCollectionView should be hidden when no transactions are in context")
  }
}
