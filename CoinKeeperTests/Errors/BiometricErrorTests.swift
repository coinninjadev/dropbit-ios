//
//  BiometricErrorTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest
import LocalAuthentication

class BiometricErrorTests: XCTestCase {
  var sut: DBTError.Biometrics!

  // MARK: initializer
  func testInitializerWithAuthenticationFailed() {
    self.sut = DBTError.Biometrics(code: .authenticationFailed)
    XCTAssertEqual(self.sut, .authenticationFailed, "initialization should set proper value")
  }

  func testInitializationWithUserCancel() {
    self.sut = DBTError.Biometrics(code: .userCancel)
    XCTAssertEqual(self.sut, .userCancel, "initialization should set proper value")
  }

  func testInitializationWithSystemCancel() {
    self.sut = DBTError.Biometrics(code: .systemCancel)
    XCTAssertEqual(self.sut, .systemCancel, "initialization should set proper value")
  }

  func testInitializationWithBiometryLockout() {
    self.sut = DBTError.Biometrics(code: .biometryLockout)
    XCTAssertEqual(self.sut, .lockedOut, "initialization should set proper value")
  }

  func testInitializationWithBiometryNotEnrolled() {
    self.sut = DBTError.Biometrics(code: .biometryNotEnrolled)
    XCTAssertEqual(self.sut, .notEnrolled, "initialization should set proper value")
  }

  func testInitializationWithBiometryNotAvailable() {
    self.sut = DBTError.Biometrics(code: .biometryNotAvailable)
    XCTAssertEqual(self.sut, .notAvailable, "initialization should set proper value")
  }

  func testInitializationWithUnusedErrorKey() {
    self.sut = DBTError.Biometrics(code: .invalidContext)
    XCTAssertEqual(self.sut, .unknown, "initialization should set proper value")
  }

  // MARK: error descriptions
  func testAuthenticationFailedErrorDescription() {
    self.sut = DBTError.Biometrics(code: .authenticationFailed)
    let expectedText = "Authentication failed"
    XCTAssertEqual(self.sut.displayMessage, expectedText)
  }

  func testNotEnrolledErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryNotEnrolled)
    let expectedText = "Not enrolled in biometric authentication"
    XCTAssertEqual(self.sut.displayMessage, expectedText)
  }

  func testBiometryNotAvailableFailedErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryNotAvailable)
    XCTAssertEqual(self.sut.displayMessage, "Biometric authentication is not available")
  }

  func testUnknownErrorDescription() {
    self.sut = DBTError.Biometrics.unknown
    XCTAssertTrue(self.sut.displayMessage.isNotEmpty)
  }

  func testSystemCancelErrorDescription() {
    self.sut = DBTError.Biometrics(code: .systemCancel)
    XCTAssertTrue(self.sut.displayMessage.isNotEmpty)
  }

  func testBiometryLockoutErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryLockout)
    XCTAssertTrue(self.sut.displayMessage.isNotEmpty)
  }

  func testUserCancelErrorDescription() {
    self.sut = DBTError.Biometrics(code: .userCancel)
    XCTAssertTrue(self.sut.displayMessage.isNotEmpty)
  }
}
