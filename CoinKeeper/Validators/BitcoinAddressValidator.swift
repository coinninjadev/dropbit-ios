//
//  BitcoinAddressValidator.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import os.log

enum BitcoinAddressValidatorError: ValidatorTypeError {
  case isInvalidBitcoinAddress
  case notBase58CheckValid
  case bech32

  var debugMessage: String {
    switch self {
    case .isInvalidBitcoinAddress:  return "Invalid bitcoin address."
    case .notBase58CheckValid:      return "Address is not properly Base58Check encoded."
    case .bech32:                   return """
      Invalid bitcoin address. \(CKStrings.dropBitWithTrademark) does not support Bech32 addresses just yet.
      """.removingMultilineLineBreaks()
    }
  }

  var displayMessage: String? {
    return debugMessage
  }

}

class BitcoinAddressValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    guard !value.lowercased().starts(with: "bc1") else {
      throw BitcoinAddressValidatorError.bech32
    }

    guard WalletManager.validateBase58Check(for: value) else {
      throw BitcoinAddressValidatorError.notBase58CheckValid
    }

    guard sanitizedAddress(in: value) != nil else {
      throw BitcoinAddressValidatorError.isInvalidBitcoinAddress
    }
  }

  /// Applies a regex to identify a Bitcoin address within the string.
  /// Passing in a string that contains extraneous text will return just the raw address.
  func sanitizedAddress(in string: String) -> String? {
    return match(forRegex: validAddressRegex, in: string)
  }

  /// matches Android regex, with escaped backslashes
  private let validAddressRegex = "((?:bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}(?![a-zA-HJ-NP-Z0-9]))((?:\\?.*&?)(?:amount=)((?:[0-9]+)(?:\\.[0-9]{1,8})?))?"

  private func match(forRegex regex: String, in text: String) -> String? {
    do {
      let regex = try NSRegularExpression(pattern: regex)
      let results: [NSTextCheckingResult] = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
      let nestedResults: [[String]] = results.map { result in
        (0..<result.numberOfRanges).map {
          guard result.range(at: $0).location != NSNotFound else { return "" }
          return NSString(string: text).substring(with: result.range(at: $0))
        }
      }

      let flattenedResults = nestedResults.flatMap({$0})
      guard flattenedResults.count >= 2 else { return nil }
      return flattenedResults[1] //desired string should be at index 1 of the group

    } catch {
      let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "address_sanitizer")
      os_log("Invalid regex: %@", log: logger, type: .error, error.localizedDescription)
      return nil
    }
  }

}
