//
//  KeypadEntryViewTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class KeypadEntryViewTests: XCTestCase {
  var sut: KeypadEntryView!

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 375, height: 375)
    self.sut = KeypadEntryView(frame: frame)
    _ = self.sut.xibSetup()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.button1, "button1 should be connected")
    XCTAssertNotNil(self.sut.button2, "button2 should be connected")
    XCTAssertNotNil(self.sut.button3, "button3 should be connected")
    XCTAssertNotNil(self.sut.button4, "button4 should be connected")
    XCTAssertNotNil(self.sut.button5, "button5 should be connected")
    XCTAssertNotNil(self.sut.button6, "button6 should be connected")
    XCTAssertNotNil(self.sut.button7, "button7 should be connected")
    XCTAssertNotNil(self.sut.button8, "button8 should be connected")
    XCTAssertNotNil(self.sut.button9, "button9 should be connected")
    XCTAssertNotNil(self.sut.button0, "button0 should be connected")

    XCTAssertNotNil(self.sut.decimalButton, "decimalButton should be connected")
    XCTAssertNotNil(self.sut.backButton, "backButton should be connected")
    XCTAssertNotNil(self.sut.allButtons, "allButtons should be connected")
  }

  // MARK: inspectable variables
  func testSettingColorSetsColorForAllButtons() {
    let initialColor = Theme.Color.primaryActionButton.color
    let expectedColor = UIColor.black

    // initial assertions
    XCTAssertEqual(self.sut.button1.currentTitleColor, initialColor, "button1 should have initial color")
    XCTAssertEqual(self.sut.button2.currentTitleColor, initialColor, "button2 should have initial color")
    XCTAssertEqual(self.sut.button3.currentTitleColor, initialColor, "button3 should have initial color")
    XCTAssertEqual(self.sut.button4.currentTitleColor, initialColor, "button4 should have initial color")
    XCTAssertEqual(self.sut.button5.currentTitleColor, initialColor, "button5 should have initial color")
    XCTAssertEqual(self.sut.button6.currentTitleColor, initialColor, "button6 should have initial color")
    XCTAssertEqual(self.sut.button7.currentTitleColor, initialColor, "button7 should have initial color")
    XCTAssertEqual(self.sut.button8.currentTitleColor, initialColor, "button8 should have initial color")
    XCTAssertEqual(self.sut.button9.currentTitleColor, initialColor, "button9 should have initial color")
    XCTAssertEqual(self.sut.button0.currentTitleColor, initialColor, "button0 should have initial color")
    XCTAssertEqual(self.sut.decimalButton.currentTitleColor, initialColor, "decimalButton should have initial color")
    XCTAssertEqual(self.sut.backButton.currentTitleColor, initialColor, "backButton should have initial color")

    // when
    self.sut.buttonColor = .black

    // then
    XCTAssertEqual(self.sut.button1.currentTitleColor, expectedColor, "button1 should have set color")
    XCTAssertEqual(self.sut.button2.currentTitleColor, expectedColor, "button2 should have set color")
    XCTAssertEqual(self.sut.button3.currentTitleColor, expectedColor, "button3 should have set color")
    XCTAssertEqual(self.sut.button4.currentTitleColor, expectedColor, "button4 should have set color")
    XCTAssertEqual(self.sut.button5.currentTitleColor, expectedColor, "button5 should have set color")
    XCTAssertEqual(self.sut.button6.currentTitleColor, expectedColor, "button6 should have set color")
    XCTAssertEqual(self.sut.button7.currentTitleColor, expectedColor, "button7 should have set color")
    XCTAssertEqual(self.sut.button8.currentTitleColor, expectedColor, "button8 should have set color")
    XCTAssertEqual(self.sut.button9.currentTitleColor, expectedColor, "button9 should have set color")
    XCTAssertEqual(self.sut.button0.currentTitleColor, expectedColor, "button0 should have set color")
    XCTAssertEqual(self.sut.decimalButton.currentTitleColor, expectedColor, "decimalButton should have set color")
    XCTAssertEqual(self.sut.backButton.currentTitleColor, expectedColor, "backButton should have set color")
  }

  // MARK: buttons contain actions
  func testDecimalButtonContainsAction() {
    let actions = self.sut.decimalButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let decimalSelector = #selector(KeypadEntryView.decimalButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(decimalSelector), "decimalButton should contain action")
  }

  func testBackButtonContainsAction() {
    let actions = self.sut.backButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let backSelector = #selector(KeypadEntryView.backButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(backSelector), "backButton should contain action")
  }

  func testButton1ContainsAction() {
    let actions = self.sut.button1.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button1Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button1Selector), "button1 should contain action")
  }

  func testButton2ContainsAction() {
    let actions = self.sut.button2.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button2Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button2Selector), "button2 should contain action")
  }

  func testButton3ContainsAction() {
    let actions = self.sut.button3.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button3Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button3Selector), "button3 should contain action")
  }

  func testButton4ContainsAction() {
    let actions = self.sut.button4.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button4Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button4Selector), "button4 should contain action")
  }

  func testButton5ContainsAction() {
    let actions = self.sut.button5.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button5Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button5Selector), "button5 should contain action")
  }

  func testButton6ContainsAction() {
    let actions = self.sut.button6.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button6Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button6Selector), "button6 should contain action")
  }

  func testButton7ContainsAction() {
    let actions = self.sut.button7.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button7Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button7Selector), "button7 should contain action")
  }

  func testButton8ContainsAction() {
    let actions = self.sut.button8.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button8Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button8Selector), "button8 should contain action")
  }

  func testButton9ContainsAction() {
    let actions = self.sut.button9.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button9Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button9Selector), "button9 should contain action")
  }

  func testButton0ContainsAction() {
    let actions = self.sut.button0.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let button0Selector = #selector(KeypadEntryView.numberButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(button0Selector), "button0 should contain action")
  }

  // MARK: initial state
  func testDecimalButtonInPinEntryModeIsDisabled() {
    self.sut.entryMode = .pin
    XCTAssertEqual(self.sut.decimalButton.alpha, 0, "decimalButton should be disabled")
  }

  func testDecimalButtonInCurrencyEntryModeIsDisabled() {
    self.sut.entryMode = .currency
    XCTAssertEqual(self.sut.decimalButton.alpha, 1, "decimalButton should be enabled")
  }

  // MARK: actions produce results
  func testNumberButtonTappedProducesResults() {
    let delegate = MockKeypadEntryViewDelegate()
    self.sut.delegate = delegate
    let expectedDigit = "5"

    self.sut.numberButtonTapped(self.sut.button5)

    XCTAssertTrue(delegate.selectedDigitWasTapped, "should tell delegate a digit was tapped")
    XCTAssertEqual(delegate.selectedDigit, expectedDigit, "delegate should have expected digit")
  }

  func testBackButtonTappedTellsDelegate() {
    let delegate = MockKeypadEntryViewDelegate()
    self.sut.delegate = delegate

    self.sut.backButtonTapped()

    XCTAssertTrue(delegate.selectedBackWasTapped, "backButton tells delegate")
  }

  func testDecimalButtonTappedTellsDelegate() {
    let delegate = MockKeypadEntryViewDelegate()
    self.sut.delegate = delegate

    self.sut.decimalButtonTapped()

    XCTAssertTrue(delegate.selectedDecimalWasTapped, "decimalButton tells delegate")
  }

  // MARK: mock delegate
  class MockKeypadEntryViewDelegate: KeypadEntryViewDelegate {
    var selectedDigitWasTapped = false
    var selectedDecimalWasTapped = false
    var selectedBackWasTapped = false

    var selectedDigit = "none"

    func selected(digit: String) {
      selectedDigitWasTapped = true
      selectedDigit = digit
    }

    func selectedDecimal() {
      selectedDecimalWasTapped = true
    }

    func selectedBack() {
      selectedBackWasTapped = true
    }
  }
}
