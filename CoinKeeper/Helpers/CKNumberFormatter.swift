//
//  CKNumberFormatter.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct CKNumberFormatter {

  static let usdCurrencyFormatter: NumberFormatter = {
    return fiatCurrencyFormatter(for: .USD)
  }()

  static let satsCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.locale = Locale.current //determines grouping/decimal separators
    formatter.usesGroupingSeparator = true
    return formatter
  }()

  static func string(forSats sats: Int) -> String {
    let formattedNumber = satsCurrencyFormatter.string(from: NSNumber(value: sats)) ?? ""
    return formattedNumber + " sats"
  }

  static func fiatCurrencyFormatter(for currency: CurrencyCode) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = currency.decimalPlaces
    formatter.minimumFractionDigits = currency.decimalPlaces
    formatter.locale = Locale.current //determines grouping/decimal separators
    formatter.usesGroupingSeparator = true
    formatter.numberStyle = .currency
    formatter.currencySymbol = currency.symbol
    return formatter
  }

}
