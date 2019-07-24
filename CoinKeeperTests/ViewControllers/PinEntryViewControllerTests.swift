//
//  PinEntryViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class PinEntryViewControllerTests: XCTestCase {
  var sut: PinEntryViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    self.sut = PinEntryViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  private func setupDelegates() -> (MockCoordinator, MockDigitEntryDisplayViewModel) {
    let mockViewModel = MockDigitEntryDisplayViewModel(view: self.sut.securePinDisplayView)
    self.sut.digitEntryDisplayViewModel = mockViewModel
    self.mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator
    return (mockCoordinator, mockViewModel)
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.keypadEntryView, "keypadEntryView should be connected")
    XCTAssertNotNil(self.sut.logoImage, "logoImage should be connected")
    XCTAssertNotNil(self.sut.securePinDisplayView, "securePinDisplayView should be connected")
    XCTAssertNotNil(self.sut.logoImageCenterYConstraint, "logoImageCenterYConstraint should be connected")
    XCTAssertNotNil(self.sut.biometricButton, "biometricButton should be connected")
    XCTAssertNotNil(self.sut.errorLabel, "errorLabel should be connected")
    XCTAssertNotNil(self.sut.lockoutBlurView, "lockoutBlurView should be connected")
    XCTAssertNotNil(self.sut.lockoutErrorLabel, "lockoutErrorLabel should be connected")
  }

  // MARK: initial state
  func testKeypadEntryViewInitialState() {
    XCTAssertEqual(self.sut.keypadEntryView.alpha, 0, "keypadEntryView should be hidden")
    XCTAssertEqual(self.sut.keypadEntryView.entryMode, .pin)
    XCTAssertTrue(self.sut.keypadEntryView.delegate === self.sut, "keypad delegate should be self.sut")
  }

  func testSecurePinDisplayViewInitialState() {
    XCTAssertEqual(self.sut.securePinDisplayView.alpha, 0, "securePinDisplayView should initially be hidden")
  }

  func testLogoImageCenterYConstraintInitialState() {
    XCTAssertEqual(self.sut.logoImageCenterYConstraint.constant, 0, "logo constraint should be 0")
  }

  func testBiometricButtonInitialState() {
    XCTAssertNil(self.sut.biometricButton.title(for: .normal), "biometric title should be nil")
    XCTAssertEqual(self.sut.biometricButton.alpha, 0, "biometricButton alpha should be 0")
  }

  func testErrorLabelInitialState() {
    let expectedText = "Incorrect PIN. Please try again."
    let expectedFont = UIFont.regular(15)
    let expectedColor = UIColor.darkPeach

    XCTAssertEqual(self.sut.errorLabel.text, expectedText, "errorLabel text should equal expected text")
    XCTAssertEqual(self.sut.errorLabel.font, expectedFont, "errorLabel font should equal expected font")
    XCTAssertEqual(self.sut.errorLabel.textColor, expectedColor, "errorLabel color should equal expected color")
  }

  // MARK: after initial animations
  func testKeyPadEntryViewAfterAnimationAlphaChanges() {
    self.sut.viewDidAppear(false)
    XCTAssertEqual(self.sut.keypadEntryView.alpha, 1, "keypadEntryView alpha should equal 1")
  }

  func testSecurePinDisplayViewAfterAnimationAlphaChanges() {
    self.sut.viewDidAppear(false)
    XCTAssertEqual(self.sut.securePinDisplayView.alpha, 1, "securePinDisplayView alpha should equal 1")
  }

  func testBiometricButtonAfterAnimationsAlphaChanges() {
    _ = setupDelegates()
    self.sut.viewDidAppear(false)
    XCTAssertEqual(self.sut.biometricButton.alpha, 1, "biometricsButton alpha should equal 1")
  }

  func testBiometricButtonIsNilIfNoBiometryAvailable() {
    let (mockCoordinator, _) = setupDelegates()
    mockCoordinator.mockBiometricType = .none
    self.sut.viewDidAppear(false)
    self.sut.setupBiometricButton()
    let actualImage = self.sut.biometricButton.image(for: .normal)?.pngData()

    XCTAssertNil(actualImage, "biometricButton image should be nil")
  }

  func testBiometricButtonIsTouchIDIfTouchIDAvailable() {
    let (mockCoordinator, _) = setupDelegates()
    mockCoordinator.mockBiometricType = .touchID
    self.sut.viewDidAppear(false)
    self.sut.setupBiometricButton()
    let actualImage = self.sut.biometricButton.image(for: .normal)?.pngData()
    let expectedImage = UIImage(named: "touchID")?.pngData()

    XCTAssertEqual(actualImage, expectedImage, "image should equal touchID image")
  }

  func testBiometricButtonIsFaceIDIfFaceIDAvailable() {
    let (mockCoordinator, _) = setupDelegates()
    mockCoordinator.mockBiometricType = .faceID
    self.sut.viewDidAppear(false)
    self.sut.setupBiometricButton()
    let actualImage = self.sut.biometricButton.image(for: .normal)?.pngData()
    let expectedImage = UIImage(named: "faceID")?.pngData()

    XCTAssertEqual(actualImage, expectedImage, "image should equal faceID image")
  }

  // MARK: buttons contain actions
  func testBiometricsButtonContainsAction() {
    let actions = self.sut.biometricButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let biometricSelector = #selector(PinEntryViewController.biometricButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(biometricSelector), "biometricsButton should contain action")
  }

  // MARK: actions produce results
  func testSelectingDigitsProducesResults() {
    let (_, mockViewModel) = setupDelegates()
    self.sut.errorLabel.isHidden = false

    self.sut.selected(digit: "4")

    XCTAssertTrue(mockViewModel.digitWasAdded, "should tell viewModel a digit was added")
    XCTAssertEqual(self.sut.errorLabel.alpha, 0, "entering a digit should hide error label")
  }

  func testAllDigitsEnteredAsksDelegateToCheckForMatch() {
    let (mockCoordinator, mockViewModel) = setupDelegates()
    mockViewModel.removeAllDigits()

    6.times { self.sut.selected(digit: "4") }

    XCTAssertTrue(mockCoordinator.checkMatchForDigitsWasCalled, "should tell delegate to check for match")
  }

  func testAllDigitsEnteredAndMatchTellsDelegateToSuccessfullyAuthenticate() {
    let (mockCoordinator, mockViewModel) = setupDelegates()
    mockViewModel.removeAllDigits()
    mockCoordinator.expectedDigits = Array(repeating: "4", count: 6).joined()

    let expectation = self.expectation(description: "successful match")
    6.times { self.sut.selected(digit: "4") }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      expectation.fulfill()
      XCTAssertTrue(mockCoordinator.successfullyAuthenticatedWasCalled, "should tell delegate of successful match")
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAllDigitsEnteredAndNotMatchingTellsViewModelToRemoveAllDigits() {
    let (mockCoordinator, mockViewModel) = setupDelegates()
    mockViewModel.removeAllDigits()
    mockCoordinator.expectedDigits = Array(repeating: "4", count: 6).joined()

    6.times { self.sut.selected(digit: "5") }

    XCTAssertTrue(mockViewModel.digitsWereRemoved, "viewmodel digits should be removed")
    XCTAssertFalse(self.sut.errorLabel.isHidden, "should unhide error label")
  }

  func testRemovingDigitTellsViewModelToRemoveDigit() {
    let (_, mockViewModel) = setupDelegates()

    2.times { self.sut.selected(digit: "2") }
    self.sut.selectedBack()

    XCTAssertTrue(mockViewModel.digitWasRemoved, "view model should remove digit")
  }

  func testRemovingAllDigitsTellsViewModelToRemoveAllAndShowError() {
    let (mockCoordinator, mockViewModel) = setupDelegates()

    let expectedDigit = "3", actualDigit = "2"
    mockCoordinator.expectedDigits = Array(repeating: expectedDigit, count: 6).joined()

    6.times { self.sut.selected(digit: actualDigit) }

    XCTAssertTrue(mockViewModel.digitsWereRemoved, "view model should remove all digits")
    XCTAssertFalse(self.sut.errorLabel.isHidden)
  }

  func testTappingBiometricsButtonTellsDelegateToTryBiometrics() {
    let (mockCoordinator, _) = setupDelegates()

    self.sut.biometricButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.tryBiometricsWasCalled, "biometricButton tap should tell delegate to try biometrics")
  }

  // MARK: mock coordinator class
  class MockCoordinator: PinEntryViewControllerDelegate, PinVerificationDelegate {
    func pinWasVerified(digits: String, for flow: SetupFlow?) {
    }

    func viewControllerPinFailureCountExceeded(_ viewController: UIViewController) {
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController) {}
    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: (() -> Void)? ) {}

    var tryBiometricsWasCalled = false
    func viewControllerDidTryBiometrics(_ pinEntryViewController: PinEntryViewController) {
      tryBiometricsWasCalled = true
    }

    var successfullyAuthenticatedWasCalled = false
    func viewControllerDidSuccessfullyAuthenticate(_ pinEntryViewController: PinEntryViewController) {
      successfullyAuthenticatedWasCalled = true
    }

    var checkMatchForDigitsWasCalled = false
    var expectedDigits: String = ""
    func checkMatch(for digits: String) -> Bool {
      checkMatchForDigitsWasCalled = true
      return expectedDigits == digits
    }

    func pinExists() -> Bool {
      return true
    }

    var mockBiometricType = BiometricType.none
    var biometricType: BiometricType {
      return mockBiometricType
    }
  }
}
