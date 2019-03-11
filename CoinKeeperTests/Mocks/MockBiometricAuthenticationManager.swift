//
// Created by BJ Miller on 2/21/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockBiometricAuthenticationManager: BiometricAuthenticationManagerType {
  var wasAskedToResetPolicy = false
  func resetPolicy() {
    wasAskedToResetPolicy = true
  }

  var canAuthenticateWithBiometricsWasCalled = false
  var mockShouldAuthenticateWithBiometrics = false
  var canAuthenticateWithBiometrics: Bool {
    canAuthenticateWithBiometricsWasCalled = true
    return mockShouldAuthenticateWithBiometrics
  }
  var biometricType: BiometricType = .none
  var loginReason: String = "foo"

  var authenticateWasCalled = false
  var completionWasCalled = false
  var errorWasCalled = false
  func authenticate(completion: @escaping () -> Void, error: ((BiometricError) -> Void)?) {
    authenticateWasCalled = true
    if canAuthenticateWithBiometrics {
      completionWasCalled = true
      completion()
    } else {
      errorWasCalled = true
      error?(.unknown)
    }
  }
}
