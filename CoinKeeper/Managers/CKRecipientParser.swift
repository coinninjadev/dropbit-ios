//
//  CKRecipientParser.swift
//  DropBit
//
//  Created by Ben Winters on 11/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol RecipientParserType: AnyObject {
  func findRecipients(inText text: String, ofTypes types: [CKRecipientType]) throws -> [CKParsedRecipient]
  func findSingleRecipient(inText text: String, ofTypes types: [CKRecipientType]) throws -> CKParsedRecipient
}

/// Evaluates text for valid strings that could be used to identify the recipient of a transaction.
class CKRecipientParser: RecipientParserType {

  let bitcoinURLParser = CKBitcoinURLParser()
  let lightningURLParser = CKLightningURLParser()
  let phoneNumberParser = CKPhoneNumberParser()

  /// Returns an array of the detected recipients.
  /// The `text` parameter can contain extraneous text.
  /// If the text seems to contain a recipient that is unsupported, this function will throw the corresponding error.
  ///
  /// NOTE: This currently will not parse a phone number with spaces within a larger block of text.
  /// That may be possible with NSDataDetector in addition to our custom parsing.
  func findRecipients(inText text: String, ofTypes types: [CKRecipientType]) throws -> [CKParsedRecipient] {
    let cleanedText = text.stringByStandardizingWhitespaces()
    guard cleanedText.isNotEmpty else { return [] }

    let words = cleanedText.components(separatedBy: " ")

    // Simple filter before applying validators
    let punctuation = CharacterSet(charactersIn: ",.?!")
    let possiblePhoneNumbers = words.filter { 10..<25 ~= $0.count }.map { $0.trimmingCharacters(in: punctuation) }
    let possibleAddresses = words.filter { $0.count >= 25 }.map { $0.trimmingCharacters(in: punctuation) }

    do {
      return try self.parse(cleanedText,
                            candidatePhoneNumbers: possiblePhoneNumbers,
                            candidateAddresses: possibleAddresses,
                            matchingTypes: types)
    } catch let error as ValidatorErrorType {
      throw CKRecipientParserError.validation(error)
    } catch {
      throw error
    }
  }

  /// Throws error if multiple recipients are found.
  func findSingleRecipient(inText text: String, ofTypes types: [CKRecipientType] = CKRecipientType.allCases) throws -> CKParsedRecipient {
    let results = try findRecipients(inText: text, ofTypes: types)
    switch results.count {
    case 0:
      throw CKRecipientParserError.noResults
    case 1:
      return results.first!
    default:
      throw CKRecipientParserError.multipleRecipients
    }
  }

  private func parse(_ fullText: String,
                     candidatePhoneNumbers: [String],
                     candidateAddresses: [String],
                     matchingTypes types: [CKRecipientType]) throws -> [CKParsedRecipient] {

    var results: [CKParsedRecipient] = []
    for type in types {
      switch type {
      case .bitcoinURL:
        results += try candidateAddresses.compactMap { try bitcoinURLParser.parse($0) }.map { .bitcoinURL($0) }
      case .phoneNumber:
        results += try candidatePhoneNumbers.compactMap { try phoneNumberParser.parse($0) }.map { .phoneNumber($0) }
      case .lightningURL:
        results += try candidateAddresses.compactMap { try lightningURLParser.parse($0) }.map { .lightningURL($0) }
      }
    }

    // Try full text as a phone number with spaces
    if types.contains(.phoneNumber), results.isEmpty {
      do {
        if let validNumber = try phoneNumberParser.parse(fullText) {
          results.append(.phoneNumber(validNumber))
        }
      } catch {
        throw error
      }
    }

    return results
  }

}
