//
//  TransactionSummaryCellViewModelTypeTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class TransactionSummaryCellViewModelTypeTests: XCTestCase {

  var sut: TransactionSummaryCellViewModelType!

  override func setUp() {
    super.setUp()
    self.sut = MockTransactionSummaryCellViewModel.defaultInstance()
  }

  func testImageAssetsExist() {
    XCTAssertNotNil(sut.incomingImage)
    XCTAssertNotNil(sut.outgoingImage)
    XCTAssertNotNil(sut.transferImage)
    XCTAssertNotNil(sut.lightningImage)
    XCTAssertNotNil(sut.invalidImage)
  }
}
