//
//  CurrencyValidityValidator.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CurrencyStringValidatorError: ValidatorTypeError {
  case isZero
  case notANumber

  var debugMessage: String {
    switch self {
    case .isZero: return "Amount cannot be zero."
    case .notANumber: return "Amount is not a number."
    }
  }

  var displayMessage: String? {
    return debugMessage
  }

}

class CurrencyStringValidator: ValidatorType<String> {

  let locale: Locale
  init(locale: Locale = .current) {
    self.locale = locale
  }

  override func validate(value: String) throws {
    let decimal = NSDecimalNumber(string: value, locale: self.locale)

    switch decimal {
    case .notANumber:
      throw CurrencyStringValidatorError.notANumber
    case .zero:
      throw CurrencyStringValidatorError.isZero
    default:
      break
    }
  }
}
