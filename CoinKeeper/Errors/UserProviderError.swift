//
//  UserProviderError.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum UserProviderError: Error, LocalizedError {
  case noData
  case noConfirmations
  case codeInvalid
  case unexpectedStatus(UserVerificationStatus)
  case userAlreadyExists(String, CreateUserBody) //user ID, body
  case resourceAlreadyExists

  var errorDescription: String? {
    switch self {
    case .noData:                           return "No data"
    case .noConfirmations:                  return "No confirmations"
    case .resourceAlreadyExists:            return "Resource already exists"
    case .codeInvalid:                      return "Verification code was incorrect"
    case .userAlreadyExists(let id, _):     return "User already exists with ID: \(id)"
    case .unexpectedStatus(let status):     return "Unexpected verification status: \(status.rawValue)"
    }
  }

  /// Check the response string for this message to determine whether to throw .codeInvalid
  static let invalidCodeMessage = "verification code invalid"

}
