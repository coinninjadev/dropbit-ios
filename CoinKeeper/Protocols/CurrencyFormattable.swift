//
//  CurrencyFormattable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencyFormattable { }

extension CurrencyFormattable {

  func amountStringWithoutSymbol(_ amount: NSDecimalNumber, _ currency: CurrencyCode) -> String? {
    let formatter = numberFormatter(forCurrency: currency, numberStyle: .decimal)
    return formatter.string(from: amount)
  }

  func amountStringWithSymbol(_ amount: NSDecimalNumber, _ currency: CurrencyCode) -> String {
    if currency.usesCustomSymbol {
      return currency.symbol + (amountStringWithoutSymbol(amount, currency) ?? "")
    } else {
      let formatter = numberFormatter(forCurrency: currency, numberStyle: .currency)
      formatter.currencySymbol = currency.symbol
      return formatter.string(from: amount) ?? "–"
    }
  }

  private func numberFormatter(forCurrency currency: CurrencyCode, numberStyle: NumberFormatter.Style) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = .current
    formatter.numberStyle = numberStyle
    let fractionDigits = currency.decimalPlaces
    let withMinFractionDigits = currency == .USD

    formatter.maximumFractionDigits = fractionDigits
    if withMinFractionDigits {
      formatter.minimumFractionDigits = fractionDigits
    }
    return formatter
  }

}
