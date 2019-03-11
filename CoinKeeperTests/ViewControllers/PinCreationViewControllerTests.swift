//
//  PinCreationViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class PinCreationViewControllerTests: XCTestCase {
  var sut: PinCreationViewController!

  override func setUp() {
    super.setUp()

    self.sut = PinCreationViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil

    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.keypadEntryView, "keypadEntryView should be connected")
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.subtitleLabel, "subtitleLabel should be connected")
    XCTAssertNotNil(self.sut.errorLabel, "errorLabel should be connected")
    XCTAssertNotNil(self.sut.securePinDisplayView, "securePinDisplayView should be connected")
  }

  // MARK: initial state
  func testErrorLabelInitialState() {
    let expectedText = "Incorrect PIN entered 3 times.\nPlease create a new PIN."
    XCTAssertTrue(self.sut.errorLabel.isHidden, "errorLabel should be initially hidden")
    XCTAssertEqual(self.sut.errorLabel.text, expectedText)
  }

  // MARK: pin entry modes
  func testPinEntryModeInitialState() {
    XCTAssertTrue(self.sut.entryMode == .pinEntry, "entryMode should initially be .pinEntry")

    let expectedTitleText = "Set Your PIN"
    XCTAssertEqual(self.sut.titleLabel.text, expectedTitleText, "titleLabel should have expected text")

    let expectedSubtitleText = "Your PIN will be used to access\nDropBit and send Bitcoin"
    XCTAssertEqual(self.sut.subtitleLabel.text, expectedSubtitleText, "subtitleLabel should have expected text")
  }

  func testPinVerificationModeInitialState() {
    let fakeDigits = Array(repeating: "5", count: 6).joined()
    self.sut.entryMode = .pinVerification(digits: fakeDigits)

    let digits = Array(repeating: "5", count: 6).joined()
    XCTAssertTrue(self.sut.entryMode == .pinVerification(digits: digits), "entryMode should be .pinVerification")

    let expectedTitleText = "Re-Enter PIN"
    XCTAssertEqual(self.sut.titleLabel.text, expectedTitleText, "titleLabel should have expected text")

    let expectedSubtitleText = "Your PIN will be used to access\nDropBit and send Bitcoin"
    XCTAssertEqual(self.sut.subtitleLabel.text, expectedSubtitleText, "subtitleLabel should have expected text")
  }

  // MARK: actions produce results
  var mockCoordinator: MockPinCreationViewControllerDelegate!
  private func setupForSelectedDigitTests() {
    mockCoordinator = MockPinCreationViewControllerDelegate()
    self.sut.generalCoordinationDelegate = mockCoordinator
    self.sut.errorLabel.isHidden = false
  }
  func testCallingSelectedDigitFirstTimeHidesErrorLabel() {
    setupForSelectedDigitTests()
    let matchingDigit = "5"
    self.sut.selected(digit: matchingDigit)

    XCTAssertTrue(self.sut.errorLabel.isHidden, "errorLabel should be hidden")
    XCTAssertFalse(mockCoordinator.pinWasFullyEntered, "pin should not be fully entered")
  }

  func testCallingSelectedDigitsFiveTimesDoesNotYetTellDelegate() {
    setupForSelectedDigitTests()
    let matchingDigit = "5"
    5.times { self.sut.selected(digit: matchingDigit) }

    XCTAssertFalse(mockCoordinator.pinWasFullyEntered, "pin should not be fully entered")
    XCTAssertEqual(mockCoordinator.digits, "", "digits should be empty")
  }

  func testCallingSelectedDigitsSixTimesTellsDelegatePinWasEntered() {
    setupForSelectedDigitTests()
    let matchingDigit = "5"
    let expectedDigits = Array(repeating: matchingDigit, count: 6).joined()
    6.times { self.sut.selected(digit: matchingDigit) }

    XCTAssertTrue(mockCoordinator.pinWasFullyEntered, "pin should be fully entered")
    XCTAssertEqual(mockCoordinator.digits, expectedDigits)
  }

  func testCallingSelectedDigitInPinVerificationMode_EqualEntries() {
    mockCoordinator = MockPinCreationViewControllerDelegate()
    let mockVerificationDelegate = MockPinVerificationDelegate()
    let matchingDigit = "2"
    self.sut.verificationDelegate = mockVerificationDelegate
    self.sut.generalCoordinationDelegate = mockCoordinator
    let firstDigits = Array(repeating: matchingDigit, count: 6).joined()
    self.sut.entryMode = .pinVerification(digits: firstDigits)
    6.times { self.sut.selected(digit: matchingDigit) }

    XCTAssertTrue(mockVerificationDelegate.pinWasVerified, "pin should be verified")
    XCTAssertFalse(mockCoordinator.pinWasFullyEntered, "coordinator should not be told about pin verified")
  }

  func testCallingSelectedDigitInPinVerificationMode_NonequalEntries() {
    mockCoordinator = MockPinCreationViewControllerDelegate()
    let mockVerificationDelegate = MockPinVerificationDelegate()
    let matchingDigit = "2"
    let nonMatchingDigit = "4"
    self.sut.verificationDelegate = mockVerificationDelegate
    self.sut.generalCoordinationDelegate = mockCoordinator
    let firstDigits = Array(repeating: matchingDigit, count: 6).joined()
    self.sut.entryMode = .pinVerification(digits: firstDigits)
    6.times { self.sut.selected(digit: nonMatchingDigit) }

    let expectedErrorText = "Incorrect PIN.\nPlease try again."
    XCTAssertEqual(self.sut.errorLabel.text, expectedErrorText, "error text should equal expected text")
    XCTAssertFalse(self.sut.errorLabel.isHidden, "errorLabel should not be hidden")

    6.times { self.sut.selected(digit: nonMatchingDigit) }
    6.times { self.sut.selected(digit: nonMatchingDigit) }
    XCTAssertTrue(mockVerificationDelegate.pinFailCountExceeded, "pin fail count should be exceeded")
  }

  func testSelectedBackActionCalledRemovesDigit() {
    let matchingDigit = "5"
    mockCoordinator = MockPinCreationViewControllerDelegate()
    self.sut.generalCoordinationDelegate = mockCoordinator
    5.times { self.sut.selected(digit: matchingDigit) }

    XCTAssertFalse(mockCoordinator.pinWasFullyEntered, "should not tell delegate that pin was entered")
    XCTAssertEqual(mockCoordinator.digits, "", "delegate's digits should be empty")
  }
}
