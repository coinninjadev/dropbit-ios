//
//  DBTAssociatedError.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension DBTError {

  enum RecipientParser: DBTErrorType {
    case multipleRecipients
    case validation(ValidatorErrorType)
    case noResults(String)

    var displayMessage: String {
      switch self {
      case .multipleRecipients:
        return "Multiplie potential recipients were found in the text."
      case .validation(let validatorError):
        return validatorError.displayMessage
      case .noResults(let pastedText):
        return "No valid recipients found in: \(pastedText.substring(start: 0, offsetBy: 100) ?? pastedText)"
      }
    }
  }

  enum UserRequest: DBTErrorType {
    case noData
    case noConfirmations
    case codeInvalid
    case unexpectedStatus(UserVerificationStatus)
    case userAlreadyExists(String, UserIdentityBody) //user ID, body
    case twilioError(UserResponse, UserIdentityBody)
    case resourceAlreadyExists
    case userNotVerified
    case noVerificationStatusFound

    var displayMessage: String {
      switch self {
      case .noData:                           return "No data"
      case .noConfirmations:                  return "No confirmations"
      case .resourceAlreadyExists:            return "Resource already exists"
      case .codeInvalid:                      return "Verification code was incorrect"
      case .twilioError:                      return "Received Twilio error for user"
      case .userAlreadyExists(let id, _):     return "User already exists with ID: \(id)"
      case .unexpectedStatus(let status):     return "Unexpected verification status: \(status.rawValue)"
      case .userNotVerified:                  return "Requested user is not a verified DropBit user"
      case .noVerificationStatusFound:        return "No verification status found for user"
      }
    }

    /// Check the response string for this message to determine whether to throw .codeInvalid
    static let invalidCodeMessage = "verification code invalid"
  }

}
