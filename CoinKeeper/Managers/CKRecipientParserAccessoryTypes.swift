//
//  CKRecipientParserAccessoryTypes.swift
//  DropBit
//
//  Created by Ben Winters on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CKParser {
  associatedtype Result
  func parse(_ string: String) throws -> Result?
}

enum CKParsedRecipient {
  case phoneNumber(GlobalPhoneNumber)
  case bitcoinURL(BitcoinURL)
  case lightningURL(LightningURL)
}

/// Matches CKParsedRecipient without requiring an associated value
enum CKRecipientType: CaseIterable {
  case phoneNumber, bitcoinURL, lightningURL
}

protocol ValidatorErrorType: DisplayableError { }

enum CKRecipientParserError: DisplayableError {
  case multipleRecipients
  case validation(ValidatorErrorType)
  case noResults

  var displayMessage: String {
    switch self {
    case .multipleRecipients:
      return "Multiplie potential recipients were found in the text."
    case .validation(let validatorError):
      return validatorError.displayMessage
    case .noResults:
      return "No valid recipients were found in the text."
    }
  }

}
