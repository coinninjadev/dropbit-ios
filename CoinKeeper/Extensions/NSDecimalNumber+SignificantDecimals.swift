//
//  NSDecimalNumber+SignificantDecimals.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NSDecimalNumber {

  var significantFractionalDecimalDigits: Int {
    return max(-self.decimalValue.exponent, 0)
  }

  /// Round off digits beyond the max decimal places for the currency
  func rounded(forCurrency currency: CurrencyCode) -> NSDecimalNumber {
    return rounded(withScale: currency.decimalPlaces)
  }

  func rounded(withScale scale: Int) -> NSDecimalNumber {
    let handler = NSDecimalNumberHandler(roundingMode: .plain,
                                         scale: Int16(scale),
                                         raiseOnExactness: false,
                                         raiseOnOverflow: false,
                                         raiseOnUnderflow: false,
                                         raiseOnDivideByZero: false)
    return self.rounding(accordingToBehavior: handler)
  }

  /// Create an NSDecimalNumber using satoshis or cents and the appropriate number of decimal places.
  convenience init(integerAmount: Int, currency: CurrencyCode) {
    let absValue = abs(integerAmount) //safe for UInt64
    self.init(mantissa: UInt64(absValue), exponent: -Int16(currency.decimalPlaces), isNegative: integerAmount < 0)
  }

  /// Convert the standard currency unit to an integer of its fractional units, e.g. $1.25 -> 125
  func asFractionalUnits(of currency: CurrencyCode) -> Int {
    guard self != NSDecimalNumber.notANumber else { return 0 }
    return self.rounded(forCurrency: currency).multiplying(byPowerOf10: Int16(currency.decimalPlaces)).intValue
  }

  func absoluteValue() -> NSDecimalNumber {
    if self < NSDecimalNumber.zero {
      let negativeValue = NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true)
      return self.multiplying(by: negativeValue)
    } else {
      return self
    }
  }

}
