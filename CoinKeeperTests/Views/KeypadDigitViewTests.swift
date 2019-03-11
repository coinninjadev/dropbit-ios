//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class KeypadDigitViewTests: XCTestCase {
  var sut: KeypadDigitView!

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 32, height: 48)
    self.sut = KeypadDigitView(frame: frame)
    _ = self.sut.xibSetup()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.circleView, "circleView should be connected")
    XCTAssertNotNil(self.sut.bottomBarView, "bottomBarView should be connected")
    XCTAssertNotNil(self.sut.letterView, "letterView should be connected")
  }

  // MARK: initial state
  func testCircleViewInitialState() {
    XCTAssertTrue(self.sut.circleView.isHidden, "circleView should initially be hidden")
  }

  func testBottomBarViewInitialState() {
    XCTAssertFalse(self.sut.bottomBarView.isHidden, "bottomBarView should initially be visible")
  }

  func testBackgroundColorInitialState() {
    XCTAssertNil(self.sut.backgroundColor, "backgroundColor should be nil")
  }

  // MARK: secure - hasDigit
  func testWhenTrueShowsCircleView() {
    self.sut.hasDigit = true
    self.sut.isSecure = true

    XCTAssertFalse(self.sut.circleView.isHidden, "circleView should be visible")
  }

  func testWhenFalseHidesCircleView() {
    self.sut.hasDigit = false
    XCTAssertTrue(self.sut.circleView.isHidden, "circleView should be hidden")
  }

  // MARK: digits mode
  func testWhenDigitSetShowsLetterView() {
    self.sut.digit = "4"
    XCTAssertFalse(self.sut.letterView.isHidden, "letterView should be visible")
  }

  func testWhenNoDigitHidesLetterView() {
    self.sut.digit = ""
    XCTAssertTrue(self.sut.letterView.isHidden, "letterView should be hidden")
  }
}
