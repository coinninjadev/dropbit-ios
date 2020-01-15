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
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testNotEnrolledErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryNotEnrolled)
    let expectedText = "Not enrolled in biometric authentication"
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testBiometryNotAvailableFailedErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryNotAvailable)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testUnknownErrorDescription() {
    self.sut = DBTError.Biometrics.unknown
    let expectedText = "If you are enrolled in biometric authentication, please try again."
    XCTAssertEqual(self.sut.errorDescription, expectedText)
  }

  func testSystemCancelErrorDescription() {
    self.sut = DBTError.Biometrics(code: .systemCancel)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testBiometryLockoutErrorDescription() {
    self.sut = DBTError.Biometrics(code: .biometryLockout)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }

  func testUserCancelErrorDescription() {
    self.sut = DBTError.Biometrics(code: .userCancel)
    XCTAssertNil(self.sut.errorDescription, "error description should be nil")
  }
}
