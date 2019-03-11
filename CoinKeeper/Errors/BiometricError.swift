//
//  BiometricError.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import LocalAuthentication

enum BiometricError: Error {
  case authenticationFailed
  case userCancel
  case systemCancel
  case lockedOut
  case notEnrolled
  case notAvailable
  case unknown

  init(code: LAError.Code) {
    switch code {
    case .authenticationFailed: self = .authenticationFailed
    case .userCancel: self = .userCancel
    case .systemCancel: self = .systemCancel
    case LAError.Code.biometryLockout: self = .lockedOut
    case LAError.Code.biometryNotEnrolled: self = .notEnrolled
    case LAError.Code.biometryNotAvailable: self = .notAvailable
    default: self = .unknown
    }
  }

  var errorDescription: String? {
    switch self {
    case .authenticationFailed: return "Authentication failed"
    case .notEnrolled: return "Not enrolled in biometric authentication"
    case .notAvailable: return nil // "Biometric authentication is not available"
    case .unknown: return "If you are enrolled in biometric authentication, please try again."
    default: return nil
    }
  }
}
