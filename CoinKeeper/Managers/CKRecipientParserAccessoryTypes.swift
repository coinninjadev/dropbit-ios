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

enum CKRecipientParserError: LocalizedError {
  case multipleRecipients
  case validation(ValidatorTypeError)
  case noResults([CKRecipientType])

  var errorDescription: String? {
    switch self {
    case .multipleRecipients:
      return "Multiplie potential recipients were found in the text."
    case .validation(let validatorError):
      return validatorError.displayMessage ?? validatorError.debugMessage
    case .noResults(let types):
      let recipientDesc = recipientDescription(for: types)
      return "No valid \(recipientDesc)were found in the text."
    }
  }

  private func recipientDescription(for types: [CKRecipientType]) -> String {
    var recipientDesc = ""
    if types.contains(.bitcoinURL) {
      recipientDesc = "Bitcoin addresses "
    }

    if types.contains(.lightningURL) {
      recipientDesc = "Lightning invoices "
    }

    if types.contains(.phoneNumber) {
      let conj = recipientDesc.isEmpty ? "" : "or "
      recipientDesc += "\(conj)phone numbers "
    }
    return recipientDesc
  }

}
