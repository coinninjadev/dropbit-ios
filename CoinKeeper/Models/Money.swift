//
//  Money.swift
//  DropBit
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// A simple struct to work with monetary amounts without a currency converter.
struct Money {

  var amount: NSDecimalNumber
  var currency: CurrencyCode

  var displayString: String {
    if currency.isFiat {
      return FiatFormatter(currency: currency, withSymbol: true).string(fromDecimal: amount) ?? ""
    } else {
      return BitcoinFormatter(symbolType: .string).string(fromDecimal: amount) ?? ""
    }
  }

}

extension Money: Equatable {
  static func == (lhs: Money, rhs: Money) -> Bool {
    return lhs.amount.isEqual(to: rhs.amount) &&
      lhs.currency == rhs.currency
  }
}
