//
//  VerificationStatusViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitch on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import XCTest

class VerificationStatusViewControllerTests: XCTestCase {
  var sut: VerificationStatusViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    self.sut = VerificationStatusViewController.newInstance(delegate: mockCoordinator)
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.serverAddressViewVerticalConstraint, "serverAddressViewVerticalConstraint should be connected")
    XCTAssertNotNil(sut.serverAddressView, "serverAddressView should be connected")
    XCTAssertNotNil(sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(sut.serverAddressBackgroundView, "serverAddressBackgroundView should be connected")
    XCTAssertNotNil(sut.phoneNumberNavigationTitle, "phoneNumberNavigationTitle should be connected")
    XCTAssertNotNil(sut.privacyLabel, "privacyLabel should be connected")
    XCTAssertNotNil(sut.verifyPhoneNumberPrimaryButton, "verifyPhoneNumberPrimaryButton should be connected")
    XCTAssertNotNil(sut.changeRemovePhoneButton, "changeRemovePhoneButton should be connected")
    XCTAssertNotNil(sut.changeRemoveTwitterButton, "changeRemoveTwitterButton should be connected")
    XCTAssertNotNil(sut.phoneVerificationStatusView, "phoneVerificationStatusView should be connected")
    XCTAssertNotNil(sut.twitterVerificationStatusView, "twitterVerificationStatusView should be connected")
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.addressButton, "addressButton should be connected")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let actions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.closeButtonWasTouched).description
    XCTAssertTrue(actions.contains(expected), "closeButton should contain action")
  }

  func testAddressButtonContainsAction() {
    let actions = sut.addressButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.addressButtonWasTouched).description
    XCTAssertTrue(actions.contains(expected), "addressButton should contain action")
  }

  func testChangeRemoveTwitterButtonContainsAction() {
    let actions = sut.changeRemoveTwitterButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.changeRemoveTwitter).description
    XCTAssertTrue(actions.contains(expected), "changeRemoveTwitterButton should contain action")
  }

  func testChangeRemovePhoneButtonContainsAction() {
    let actions = sut.changeRemovePhoneButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.changeRemovePhone).description
    XCTAssertTrue(actions.contains(expected), "changeRemovePhoneButton should contain action")
  }

  func testVerifyPhoneButtonContainsAction() {
    let actions = sut.verifyPhoneNumberPrimaryButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.verifyPhoneNumber).description
    XCTAssertTrue(actions.contains(expected), "verifyPhoneNumberPrimaryButton should contain action")
  }

  func testVerifyTwitterButtonContainsAction() {
    let actions = sut.verifyTwitterPrimaryButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(VerificationStatusViewController.verifyTwitter).description
    XCTAssertTrue(actions.contains(expected), "verifyTwitterPrimaryButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTellsCoordinator() {
    sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didSelectClose)
  }

  func testVerifyPhoneButtonTellsCoordinator() {
    sut.verifyPhoneNumberPrimaryButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didSelectVerifyPhone)
  }

  func testVerifyTwitterButtonmTellsCoordinator() {
    sut.verifyTwitterPrimaryButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didSelectVerifyTwitter)
  }

  func testChangeRemoveTwitterButtonTellsCoordinator() {
    sut.changeRemoveTwitterButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didChangeRemoveTwitter)
  }

  func testChangeRemovePhoneButtonTellsCoordinator() {
    sut.changeRemovePhoneButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didChangeRemovePhone)
  }

  // MARK: private
  class MockCoordinator: VerificationStatusViewControllerDelegate {
    func verifiedPhoneNumber() -> GlobalPhoneNumber? {
      return nil
    }

    func verifiedTwitterHandle() -> String? {
      return nil
    }

    var didSelectAddressButton = false
    func viewControllerDidRequestAddresses() -> [ServerAddressViewModel] {
      didSelectAddressButton = true
      return []
    }

    func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL) {}

    var didSelectVerifyPhone = false
    func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController) {
      didSelectVerifyPhone = true
    }

    var didSelectVerifyTwitter = false
    func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) {
      didSelectVerifyTwitter = true
    }

    var didChangeRemovePhone = false
    func viewControllerDidRequestToUnverifyPhone(_ viewController: UIViewController, successfulCompletion: @escaping CKCompletion) {
      didChangeRemovePhone = true
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? ) {
      didSelectClose = true
    }

    var didChangeRemoveTwitter = false
    func viewControllerDidRequestToUnverifyTwitter(_ viewController: UIViewController, successfulCompletion: @escaping CKCompletion) {
      didChangeRemoveTwitter = true
    }

    var didSelectClose = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      didSelectClose = true
    }

    var suspendAuthenticationOnceUntil: Date?
  }
}
