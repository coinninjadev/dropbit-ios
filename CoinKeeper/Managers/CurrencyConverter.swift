//
//  CurrencyConverter.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencyConverterProvider {
  var rateManager: ExchangeRateManager { get }
  var fromAmount: NSDecimalNumber { get set }
  var fromCurrency: CurrencyCode { get set }
  var toCurrency: CurrencyCode { get set }
  var fiatCurrency: CurrencyCode { get }
}

extension CurrencyConverterProvider {
  func generateCurrencyConverter() -> CurrencyConverter {
    return CurrencyConverter(rates: rateManager.exchangeRates,
                             fromAmount: fromAmount,
                             fromCurrency: fromCurrency,
                             toCurrency: toCurrency,
                             fiatCurrency: fiatCurrency)
  }

  func generateCurrencyConverter(withBTCAmount btcAmount: NSDecimalNumber) -> CurrencyConverter {
    let existingConverter = generateCurrencyConverter()
    return CurrencyConverter(btcFromAmount: btcAmount, converter: existingConverter)
  }

}

struct CurrencyConverter: CurrencyFormattable {

  static let sampleRates: ExchangeRates = [.BTC: 1, .USD: 7000]

  let rates: ExchangeRates
  var fromAmount: NSDecimalNumber
  var fromCurrency: CurrencyCode
  var toCurrency: CurrencyCode

  /// The immutable fiat CurrencyCode used by this converter.
  let fiatCurrency: CurrencyCode

  init(rates: ExchangeRates, fromAmount: NSDecimalNumber, fromCurrency: CurrencyCode, toCurrency: CurrencyCode, fiatCurrency: CurrencyCode = .USD) {
    self.rates = rates
    self.fromAmount = fromAmount
    self.fromCurrency = fromCurrency
    self.toCurrency = toCurrency
    self.fiatCurrency = fiatCurrency
  }

  /// Copies the existing values from the supplied converter and replaces the fromAmount with the newAmount.
  init(newAmount: NSDecimalNumber, converter: CurrencyConverter) {
    self.fromAmount = newAmount
    self.rates = converter.rates
    self.fromCurrency = converter.fromCurrency
    self.toCurrency = converter.toCurrency
    self.fiatCurrency = converter.fiatCurrency
  }

  init(btcFromAmount: NSDecimalNumber, converter: CurrencyConverter) {
    self.fromAmount = btcFromAmount
    self.rates = converter.rates
    self.fromCurrency = .BTC
    self.toCurrency = converter.fiatCurrency
    self.fiatCurrency = converter.fiatCurrency
  }

  func convertedAmount() -> NSDecimalNumber? {
    guard fromAmount.isNumber else { return nil }
    guard let fromDouble = rates[fromCurrency], let toDouble = rates[toCurrency] else { return nil }

    let fromRate = NSDecimalNumber(value: fromDouble)
    let toRate = NSDecimalNumber(value: toDouble)

    guard fromRate.isPositiveNumber, toRate.isPositiveNumber else { return nil }

    let baseAmount = fromAmount.dividing(by: fromRate)
    let targetAmount = baseAmount.multiplying(by: toRate)
    return targetAmount.rounded(forCurrency: toCurrency)
  }

  var fromDisplayValue: String {
    return amountStringWithSymbol(forCurrency: fromCurrency) ?? "–"
  }

  var toDisplayValue: String {
    return amountStringWithSymbol(forCurrency: toCurrency) ?? "–"
  }

  var btcAmount: NSDecimalNumber {
    return amount(forCurrency: .BTC) ?? .zero
  }

  var fiatAmount: NSDecimalNumber {
    return amount(forCurrency: fiatCurrency) ?? .zero
  }

  func otherCurrency(forCurrency currency: CurrencyCode) -> CurrencyCode {
    if currency == .BTC {
      return self.fiatCurrency
    } else {
      return .BTC
    }
  }

  /*
   The internal functions below are intended to be used by both the computed properties of CurrencyConverter
   as well as other objects where it is more convenient to supply the desired currency,
   if they don't easily know whether they want the fromCurrency or toCurrency.
   */

  func amount(forCurrency currency: CurrencyCode) -> NSDecimalNumber? {
    switch currency {
    case fromCurrency:  return fromAmount
    case toCurrency:    return convertedAmount()
    default:            return nil
    }
  }

  func amountStringWithSymbol(forCurrency currency: CurrencyCode) -> String? {
    guard let amt = amount(forCurrency: currency) else { return nil }
    return amountStringWithSymbol(amt, currency)
  }

  func attributedStringWithSymbol(forCurrency currency: CurrencyCode, ofSize size: Int = 20) -> NSAttributedString? {
    if let symbol = currency.attributedStringSymbol(ofSize: size),
      let amt = amount(forCurrency: currency),
      let amtString = amountStringWithoutSymbol(amt, currency) {
      return symbol + NSAttributedString(string: amtString)

    } else {
      let withSymbol = amountStringWithSymbol(forCurrency: currency)
      return withSymbol.map { NSAttributedString(string: $0) }
    }
  }

}
