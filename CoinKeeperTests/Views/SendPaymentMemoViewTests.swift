//
//  SendPaymentMemoViewTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SendPaymentMemoViewTests: XCTestCase {

  var sut: SendPaymentMemoView!

  let frame = CGRect(x: 0, y: 0, width: 252, height: 48)

  override func setUp() {
    super.setUp()
    self.sut = SendPaymentMemoView(frame: frame)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.topBackgroundView, "topBackgroundView should be connected")
    XCTAssertNotNil(self.sut.bottomBackgroundView, "bottomBackgroundView should be connected")
    XCTAssertNotNil(self.sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(self.sut.separatorView, "separatorView should be connected")
    XCTAssertNotNil(self.sut.checkboxBackgroundView, "checkboxBackgroundView should be connected")
    XCTAssertNotNil(self.sut.checkboxImage, "checkboxImage should be connected")
    XCTAssertNotNil(self.sut.checkboxDescriptionLabel, "checkboxDescriptionLabel should be connected")
  }

}
