//
//  BitcoinAddressValidator.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

enum BitcoinAddressValidatorError: ValidatorTypeError {
  case isInvalidBitcoinAddress
  case notBase58CheckValid
  case notBech32Valid

  var debugMessage: String {
    switch self {
    case .isInvalidBitcoinAddress:  return "Invalid bitcoin address."
    case .notBase58CheckValid:      return "Address is not properly Base58Check encoded."
    case .notBech32Valid:
      return """
      Address is not properly Bech32 encoded.
      Please check that you have the correct address and try again.
      """.removingMultilineLineBreaks()
    }
  }

  var displayMessage: String? {
    return debugMessage
  }

}

class BitcoinAddressValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    let address = value.lowercased()
    var error: BitcoinAddressValidatorError?
    let possibleHRPs = ["bc", "tb"]
    let addressStartsWithHRP = possibleHRPs.contains(where: { address.starts(with: $0) })

    if addressStartsWithHRP {
      if !WalletManager.validateBech32Encoding(for: address) {
        error = .notBech32Valid
      }
    } else {
      if !WalletManager.validateBase58Check(for: value) {
        error = .notBase58CheckValid
      } else if sanitizedAddress(in: value) == nil {
        error = .isInvalidBitcoinAddress
      }
    }

    if let existingError = error {
      throw existingError
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
      log.error(error, message: "Invalid regex")
      return nil
    }
  }

}
