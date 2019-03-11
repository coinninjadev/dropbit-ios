//
//  SecurePinDisplayViewTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class SecurePinDisplayViewTests: XCTestCase {
  var sut: SecurePinDisplayView!

  let frame = CGRect(x: 0, y: 0, width: 252, height: 48)

  override func setUp() {
    super.setUp()
    self.sut = SecurePinDisplayView(frame: frame)
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.secureDigitView1, "secureDigitView1 should be connected")
    XCTAssertNotNil(self.sut.secureDigitView2, "secureDigitView2 should be connected")
    XCTAssertNotNil(self.sut.secureDigitView3, "secureDigitView3 should be connected")
    XCTAssertNotNil(self.sut.secureDigitView4, "secureDigitView4 should be connected")
    XCTAssertNotNil(self.sut.secureDigitView5, "secureDigitView5 should be connected")
    XCTAssertNotNil(self.sut.secureDigitView6, "secureDigitView6 should be connected")
  }

  // MARK: initialization
  func testInitializationClearsDigits() {
    self.sut.showNumberOfDigits(4)

    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertTrue(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have digit")
    XCTAssertTrue(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have digit")
    XCTAssertTrue(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")

    self.sut = SecurePinDisplayView(frame: self.frame)
    self.sut.awakeFromNib()

    XCTAssertFalse(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")
  }

  func testInitialBackgroundColorIsClear() {
    XCTAssertEqual(self.sut.backgroundColor, UIColor.clear, "backgroundColor should be clear")
  }

  // MARK: adding digit
  func testAddingDigitOnlyShowsFirstSecureView() {
    self.sut.showNumberOfDigits(0)

    // initial assertions
    XCTAssertFalse(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")

    // when
    self.sut.showNumberOfDigits(1)

    // then
    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertFalse(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")
  }

  func testWhenAlready6DigitsDoesNotAdd7thDigit() {
    self.sut.showNumberOfDigits(6)

    // initial assertions
    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertTrue(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have digit")
    XCTAssertTrue(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have digit")
    XCTAssertTrue(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have digit")
    XCTAssertTrue(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have digit")
    XCTAssertTrue(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have digit")

    // when
    self.sut.showNumberOfDigits(7)

    // then
    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertTrue(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have digit")
    XCTAssertTrue(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have digit")
    XCTAssertTrue(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have digit")
    XCTAssertTrue(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have digit")
    XCTAssertTrue(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have digit")
  }

  // MARK: removing digits
  func testRemovingDigitWhenSomeAlreadyEnteredRemovesDigit() {
    self.sut.showNumberOfDigits(4)

    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertTrue(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have digit")
    XCTAssertTrue(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have digit")
    XCTAssertTrue(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")

    self.sut.showNumberOfDigits(3)

    XCTAssertTrue(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have digit")
    XCTAssertTrue(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have digit")
    XCTAssertTrue(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")
  }

  func testRemovingDigitWhenNoDigitsAreSelectedDoesNothing() {
    self.sut.showNumberOfDigits(0)

    XCTAssertFalse(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")

    self.sut.showNumberOfDigits(-1)

    XCTAssertFalse(self.sut.secureDigitView1.hasDigit, "secureDigitView1 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView2.hasDigit, "secureDigitView2 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView3.hasDigit, "secureDigitView3 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView4.hasDigit, "secureDigitView4 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView5.hasDigit, "secureDigitView5 should have not digit")
    XCTAssertFalse(self.sut.secureDigitView6.hasDigit, "secureDigitView6 should have not digit")
  }

}
