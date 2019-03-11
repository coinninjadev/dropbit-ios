//
//  PhoneNumberStatusViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitch on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import XCTest

class PhoneNumberStatusViewControllerTests: XCTestCase {
  var sut: PhoneNumberStatusViewController!

  override func setUp() {
    super.setUp()
    self.sut = PhoneNumberStatusViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.phoneNumberNavigationTitle, "phoneNumberNavigationTitle should be connected")
    XCTAssertNotNil(self.sut.privacyLabel, "privacyLabel should be connected")
    XCTAssertNotNil(self.sut.verifyPhoneNumberPrimaryButton, "verifyPhoneNumberPrimaryButton should be connected")
    XCTAssertNotNil(self.sut.changeRemoveButton, "changeRemoveButton should be connected")
    XCTAssertNotNil(self.sut.unverifiedPhoneStackView, "unverifiedPhoneStackView should be connected")
    XCTAssertNotNil(self.sut.verifiedPhoneStackView, "verifiedPhoneStackView should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.verifyPhoneNumberLabel, "verifyPhoneNumberLabel should be connected")
    XCTAssertNotNil(self.sut.phoneNumberLabel, "phoneNumberLabel should be connected")
  }

  func testButtonActions() {
    let closeButtonAction = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let verifyPhoneNumberAction = self.sut.verifyPhoneNumberPrimaryButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(PhoneNumberStatusViewController.closeButtonWasTouched)
    let verifySelector = #selector(PhoneNumberStatusViewController.verifyPhoneNumberPrimaryButtonWasTouched)
    XCTAssertTrue(closeButtonAction.contains(closeSelector.description), "wordButtonOne should contain action")
    XCTAssertTrue(verifyPhoneNumberAction.contains(verifySelector.description), "wordButtonTwo should contain action")
  }
}
