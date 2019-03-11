//
//  BiometricAuthenticationManagerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class BiometricAuthenticationManagerTests: XCTestCase {
  var sut: BiometricAuthenticationManager!

  override func setUp() {
    super.setUp()
    self.sut = BiometricAuthenticationManager()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testCanAuthenticateWithBiometricsAsksContextIfItCanEvaluatePolicy() {
    let mockLAContext = MockLAContext()
    self.sut = BiometricAuthenticationManager(context: mockLAContext)

    _ = self.sut.canAuthenticateWithBiometrics

    XCTAssertTrue(mockLAContext.wasAskedIfCanEvaluatePolicy)
  }

  func testBiometricTypeGetsBiometryTypeFromContext() {
    let expectedType = BiometricType.faceID
    let mockLAContext = MockLAContext()
    mockLAContext.shouldEvaluatePolicy = true
    self.sut = BiometricAuthenticationManager(context: mockLAContext)
    mockLAContext.biometryType = .faceID

    let actualType = self.sut.biometricType

    XCTAssertEqual(actualType, expectedType)
  }

  func testLoginReasonForTouchIDReturnsExpectedText() {
    let mockLAContext = MockLAContext()
    mockLAContext.shouldEvaluatePolicy = true
    mockLAContext.biometryType = .touchID
    self.sut = BiometricAuthenticationManager(context: mockLAContext)
    let expectedText = "Use Touch ID to unlock your \(CKStrings.dropBitWithTrademark) wallet"

    let actualText = self.sut.loginReason

    XCTAssertEqual(actualText, expectedText, "login reason should be returned")
  }

  func testLoginReasonForFaceIDReturnsExpectedText() {
    let mockLAContext = MockLAContext()
    mockLAContext.shouldEvaluatePolicy = true
    mockLAContext.biometryType = .faceID
    self.sut = BiometricAuthenticationManager(context: mockLAContext)
    let expectedText = "Use Face ID to unlock your \(CKStrings.dropBitWithTrademark) wallet"

    let actualText = self.sut.loginReason

    XCTAssertEqual(actualText, expectedText, "login reason should be returned")
  }

  // MARK: Authentication
  func testAuthenticationWithBiometricsDisabledBehavesProperly() {
    var didCallErrorHandler = false
    var errorObject: BiometricError!
    var completionWasCalled = false
    let mockLAContext = MockLAContext()
    mockLAContext.shouldEvaluatePolicy = false
    self.sut = BiometricAuthenticationManager(context: mockLAContext)

    self.sut.authenticate(
      completion: { completionWasCalled = true },
      error: { error in
        didCallErrorHandler = true
        errorObject = error
    }
    )

    XCTAssertFalse(completionWasCalled, "completion handler should not be called in error state")
    XCTAssertTrue(mockLAContext.wasAskedIfCanEvaluatePolicy, "should ask policy if it can evaluate policy")
    XCTAssertTrue(didCallErrorHandler, "error handler should be called in error state")
    XCTAssertEqual(errorObject, .notEnrolled, "error should report that user is not enrolled")
  }

  func testAuthenticationWithBiometricsEnabledBehavesProperly() {
    let mockLAContext = MockLAContext()
    mockLAContext.shouldEvaluatePolicy = true
    self.sut = BiometricAuthenticationManager(context: mockLAContext)

    self.sut.authenticate(completion: { }, error: { _ in XCTFail("should have succeeded" )})

    XCTAssertTrue(mockLAContext.wasAskedIfCanEvaluatePolicy, "should ask context if it can evaluate policy")
    XCTAssertTrue(mockLAContext.wasAskedToEvaluatePolicy, "should aks context to evaluate policy")
    XCTAssertNil(mockLAContext.evaluationError, "error object should be nil upon success")
  }
}

import LocalAuthentication
class MockLAContext: LocalAuthenticationContextType {
  var wasAskedIfCanEvaluatePolicy = false
  var shouldEvaluatePolicy = false
  var evaluationError: LAError?
  func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
    wasAskedIfCanEvaluatePolicy = true
    return shouldEvaluatePolicy
  }

  var wasAskedToEvaluatePolicy = false
  func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
    wasAskedToEvaluatePolicy = true
    if shouldEvaluatePolicy {
      reply(true, nil)
    } else {
      reply(false, evaluationError)
    }
  }

  var biometryType: LABiometryType = .none
}
