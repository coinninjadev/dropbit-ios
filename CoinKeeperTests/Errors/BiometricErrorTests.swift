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
  var sut: BiometricError!

  // MARK: initializer
  func testInitializerWithAuthenticationFailed() {
    self.sut = BiometricError(code: .authenticationFailed)
    XCTAssertEqual(self.sut, .authenticationFailed, "initialization should set proper value")
  }

  func testInitializationWithUserCancel() {
    self.sut = BiometricError(code: .userCancel)
    XCTAssertEqual(self.sut, .userCancel, "initialization should set proper value")
  }

  func testInitializationWithSystemCancel() {
    self.sut = BiometricError(code: .systemCancel)
    XCTAssertEqual(self.sut, .systemCancel, "initialization should set proper value")
  }

  func testInitializationWithBiometryLockout() {
    self.sut = BiometricError(code: .biometryLockout)
    XCTAssertEqual(self.sut, .lockedOut, "initialization should set proper value")
  }

  func testInitializationWithBiometryNotEnrolled() {
    self.sut = BiometricError(code: .biometryNotEnrolled)
    XCTAssertEqual(self.sut, .notEnrolled, "initialization should set proper value")
  }

  func testInitializationWithBiometryNotAvailable() {
    self.sut = BiometricError(code: .biometryNotAvailable)
    XCTAssertEqual(self.sut, .notAvailable, "initialization should set proper value")
  }

  func testInitializationWithUnusedErrorKey() {
    self.sut = BiometricError(code: .invalidContext)
    XCTAssertEqual(self.sut, .unknown, "initialization should set proper value")
  }

  // MARK: error descriptions
  func testAuthenticationFailedErrorDescription() {
    self.sut = BiometricError(code: .authenticationFailed)
    let expectedText = "Authentication failed"
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testNotEnrolledErrorDescription() {
    self.sut = BiometricError(code: .biometryNotEnrolled)
    let expectedText = "Not enrolled in biometric authentication"
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testBiometryNotAvailableFailedErrorDescription() {
    self.sut = BiometricError(code: .biometryNotAvailable)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testUnknownErrorDescription() {
    self.sut = BiometricError.unknown
    let expectedText = "If you are enrolled in biometric authentication, please try again."
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testSystemCancelErrorDescription() {
    self.sut = BiometricError(code: .systemCancel)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testBiometryLockoutErrorDescription() {
    self.sut = BiometricError(code: .biometryLockout)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testUserCancelErrorDescription() {
    self.sut = BiometricError(code: .userCancel)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }
}
