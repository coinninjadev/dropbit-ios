//
//  DigitEntryDisplayViewModelTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class DigitEntryDisplayViewModelTests: XCTestCase {
  var sut: DigitEntryDisplayViewModel!
  var view: SecurePinDisplayView!

  func resetViews() {
    self.view.allViews.forEach { view in view.hasDigit = false }
  }

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 252, height: 48)
    self.view = SecurePinDisplayView(frame: frame)
    self.view.awakeFromNib()
    self.sut = DigitEntryDisplayViewModel(view: self.view)
  }

  override func tearDown() {
    self.sut = nil
    self.view = nil
    super.tearDown()
  }

  // MARK: add(digit:) method
  func testAddingFirstDigitSetsFirstDigitInArray() {
    // initial
    XCTAssertTrue(self.sut.digits.isEmpty, "digits array should be empty")
    XCTAssertFalse(self.view.secureDigitView1.hasDigit, "view1 should be empty")
    XCTAssertFalse(self.view.secureDigitView2.hasDigit, "view2 should be empty")
    XCTAssertFalse(self.view.secureDigitView3.hasDigit, "view3 should be empty")
    XCTAssertFalse(self.view.secureDigitView4.hasDigit, "view4 should be empty")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")

    // when
    _ = self.sut.add(digit: "1")

    // then
    XCTAssertEqual(self.sut.digits.count, 1, "digits array should have 1 element")
    XCTAssertEqual(self.sut.digits.first, "1", "first element should equal what was input")
    XCTAssertTrue(self.view.secureDigitView1.hasDigit, "view1 should have a value")
    XCTAssertFalse(self.view.secureDigitView2.hasDigit, "view2 should be empty")
    XCTAssertFalse(self.view.secureDigitView3.hasDigit, "view3 should be empty")
    XCTAssertFalse(self.view.secureDigitView4.hasDigit, "view4 should be empty")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")
  }

  // MARK: removeDigit method
  func testRemoveDigitClearsLastDigit() {
    5.times { _ = self.sut.add(digit: "5") }
    XCTAssertEqual(self.sut.digits.count, 5, "there should be 5 initial digits")
    XCTAssertTrue(self.view.secureDigitView1.hasDigit, "view1 should have a value")
    XCTAssertTrue(self.view.secureDigitView2.hasDigit, "view2 should have a value")
    XCTAssertTrue(self.view.secureDigitView3.hasDigit, "view3 should have a value")
    XCTAssertTrue(self.view.secureDigitView4.hasDigit, "view4 should have a value")
    XCTAssertTrue(self.view.secureDigitView5.hasDigit, "view5 should have a value")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")

    self.sut.removeDigit()

    XCTAssertEqual(self.sut.digits.count, 4, "there should be 4 remaining digits")
    XCTAssertTrue(self.view.secureDigitView1.hasDigit, "view1 should have a value")
    XCTAssertTrue(self.view.secureDigitView2.hasDigit, "view2 should have a value")
    XCTAssertTrue(self.view.secureDigitView3.hasDigit, "view3 should have a value")
    XCTAssertTrue(self.view.secureDigitView4.hasDigit, "view4 should have a value")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")
  }

  func testRemoveDigitWhenArrayIsEmptyDoesNothing() {
    self.sut.removeAllDigits()
    XCTAssertTrue(self.sut.digits.isEmpty, "array should be initially empty")
    XCTAssertFalse(self.view.secureDigitView1.hasDigit, "view1 should be empty")
    XCTAssertFalse(self.view.secureDigitView2.hasDigit, "view2 should be empty")
    XCTAssertFalse(self.view.secureDigitView3.hasDigit, "view3 should be empty")
    XCTAssertFalse(self.view.secureDigitView4.hasDigit, "view4 should be empty")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")

    self.sut.removeDigit()

    XCTAssertTrue(self.sut.digits.isEmpty, "array should still be empty")
    XCTAssertFalse(self.view.secureDigitView1.hasDigit, "view1 should be empty")
    XCTAssertFalse(self.view.secureDigitView2.hasDigit, "view2 should be empty")
    XCTAssertFalse(self.view.secureDigitView3.hasDigit, "view3 should be empty")
    XCTAssertFalse(self.view.secureDigitView4.hasDigit, "view4 should be empty")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")
  }

  // MARK: removeAllDigits
  func testRemoveAllDigitsRemovesAllDigits() {
    // given
    5.times { _ = self.sut.add(digit: "5") }

    // initial assertions
    XCTAssertEqual(self.sut.digits.count, 5, "there should be 5 initial digits")
    XCTAssertTrue(self.view.secureDigitView1.hasDigit, "view1 should have a value")
    XCTAssertTrue(self.view.secureDigitView2.hasDigit, "view2 should have a value")
    XCTAssertTrue(self.view.secureDigitView3.hasDigit, "view3 should have a value")
    XCTAssertTrue(self.view.secureDigitView4.hasDigit, "view4 should have a value")
    XCTAssertTrue(self.view.secureDigitView5.hasDigit, "view5 should have a value")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")

    // when
    self.sut.removeAllDigits()

    // then
    XCTAssertTrue(self.sut.digits.isEmpty, "array should be empty")
    XCTAssertFalse(self.view.secureDigitView1.hasDigit, "view1 should be empty")
    XCTAssertFalse(self.view.secureDigitView2.hasDigit, "view2 should be empty")
    XCTAssertFalse(self.view.secureDigitView3.hasDigit, "view3 should be empty")
    XCTAssertFalse(self.view.secureDigitView4.hasDigit, "view4 should be empty")
    XCTAssertFalse(self.view.secureDigitView5.hasDigit, "view5 should be empty")
    XCTAssertFalse(self.view.secureDigitView6.hasDigit, "view6 should be empty")
  }

  // MARK: all digits entered
  func testWhenAllDigitsEntered() {
    self.sut.removeAllDigits()
    _ = self.sut.add(digit: "2")
    XCTAssertFalse(self.sut.allDigitsEntered, "not all digits are entered")

    6.times { _ = self.sut.add(digit: "2") }

    XCTAssertEqual(self.sut.digits.count, 6, "count should equal 6")
    XCTAssertTrue(self.sut.allDigitsEntered, "all digits are entered")

    _ = self.sut.add(digit: "4")
    XCTAssertEqual(self.sut.digits.count, 6, "count should still equal 6")
  }

}
