//
//  BiometricAuthenticationManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import LocalAuthentication

protocol BiometricAuthenticationManagerType {
  var canAuthenticateWithBiometrics: Bool { get }
  var biometricType: BiometricType { get }
  var loginReason: String { get }
  func authenticate(completion: @escaping () -> Void, error: ((BiometricError) -> Void)?)
  func resetPolicy()
}

protocol LocalAuthenticationContextType {
  func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
  func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void)
  var biometryType: LABiometryType { get }
}
extension LAContext: LocalAuthenticationContextType {}

enum BiometricType {
  case none, touchID, faceID

  var description: String {
    switch self {
    case .none: return ""
    case .faceID: return "Face ID"
    case .touchID: return "Touch ID"
    }
  }
}

class BiometricAuthenticationManager: BiometricAuthenticationManagerType {

  private var context: LocalAuthenticationContextType

  init(context: LocalAuthenticationContextType = LAContext()) {
    self.context = context
  }

  func resetPolicy() {
    self.context = LAContext()
  }

  var canAuthenticateWithBiometrics: Bool {
    var error: NSError?
    let canAuth = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    return canAuth
  }

  var biometricType: BiometricType {
    let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    guard canEvaluate else { return .none }
    switch context.biometryType {
    case .none: return .none
    case .touchID: return .touchID
    case .faceID: return .faceID
    @unknown default: return .none
    }
  }

  var loginReason: String {
    switch biometricType {
    case .none: return ""
    case .touchID: return "Use Touch ID to unlock your \(CKStrings.dropBitWithTrademark) wallet"
    case .faceID: return "Use Face ID to unlock your \(CKStrings.dropBitWithTrademark) wallet"
    }
  }

  func authenticate(completion: @escaping () -> Void, error: ((BiometricError) -> Void)?) {
    guard canAuthenticateWithBiometrics else {
      error?(.notEnrolled)
      return
    }

    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: loginReason) { (success, evaluationError) in
      DispatchQueue.main.async {
        if success {
          completion()
        } else {
          guard let evaluationError = evaluationError as? LAError else { return }
          error?(BiometricError(code: evaluationError.code))
        }
      }
    }
  }
}
