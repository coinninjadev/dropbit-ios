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
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    self.mockCoordinator = MockCoordinator()
    sut = DeviceVerificationViewController.newInstance(delegate: mockCoordinator, entryMode: .phoneNumberEntry, setupFlow: nil)
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

  class MockCoordinator: DeviceVerificationViewControllerDelegate {

    func viewController(_ viewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber) { }
    func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController, temporaryUserId: String) { }
    func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController) { }
    func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) { }

    func viewController(_ codeEntryViewController: DeviceVerificationViewController,
                        didEnterCode code: String,
                        forUserId userId: String,
                        completion: @escaping (Bool) -> Void) {
      completion(true)
    }

    func viewControllerShouldShowSkipButton() -> Bool {
      return true
    }

  }
}
