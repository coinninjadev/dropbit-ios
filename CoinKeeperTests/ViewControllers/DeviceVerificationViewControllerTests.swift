//
//  DeviceVerificationViewControllerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import UIKit

class DeviceVerificationViewControllerTests: XCTestCase {
  var sut: DeviceVerificationViewController!

  override func setUp() {
    super.setUp()
    sut = DeviceVerificationViewController.makeFromStoryboard()
    _ = sut.view
  }

  override func tearDown() {
    super.tearDown()
    sut = nil
  }

  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.keypadEntryView, "keypadEntryView should be connected")
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.subtitleLabel, "subtitleLabel should be connected")
    XCTAssertNotNil(self.sut.errorLabel, "errorLabel should be connected")
    XCTAssertNotNil(self.sut.phoneNumberEntryView, "phoneNumberEntryView should be connected")
    XCTAssertNotNil(self.sut.codeDisplayView, "codeDisplayView should be connected")
    XCTAssertNotNil(self.sut.resendCodeButton, "resendCodeButton should be connected")
  }

  func testResendButtonContainsAction() {
    let actions = self.sut.resendCodeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let resendSelector = #selector(DeviceVerificationViewController.resendTextMessage(_:))
    XCTAssertTrue(actions.contains(resendSelector.description), "resendCodeButton should contain action")
  }

}
