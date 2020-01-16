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

protocol ValidatorErrorType: DBTErrorType { }
