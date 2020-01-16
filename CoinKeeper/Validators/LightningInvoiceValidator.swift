//
//  LightningInvoiceValidator.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum LightningInvoiceValidatorError: ValidatorErrorType {
  case isInvalidLightningInvoice

  var displayMessage: String {
    switch self {
    case .isInvalidLightningInvoice:  return "Invalid Lightning Invoice"
    }
  }

}

class LightningInvoiceValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    let invoice = value.lowercased()
    var error: LightningInvoiceValidatorError?

    if sanitizedInvoice(in: invoice) == nil {
      error = .isInvalidLightningInvoice
    }

    if let existingError = error {
      throw existingError
    }
  }

  /// Passing in a string that contains extraneous text will return just the raw address.
  func sanitizedInvoice(in string: String) -> String? {
    return match(forRegex: validInvoiceRegex, in: string)
  }

  private var regexPrefix: String {
    return "[bc]|[tb]"
  }

  private var validInvoiceRegex: String {
    return "ln\(regexPrefix)"
  }

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
