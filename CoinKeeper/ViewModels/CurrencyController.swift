//
//  CurrencyController.swift
//  DropBit
//
//  Created by BJ Miller on 4/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SelectedCurrency: String {
  case BTC, fiat

  mutating func toggle() {
    switch self {
    case .BTC:  self = .fiat
    case .fiat: self = .BTC
    }
  }

  var description: String {
    return self.rawValue
  }

  var code: CurrencyCode {
    switch self {
    case .fiat: return .USD
    case .BTC:  return .BTC
    }
  }

}

protocol SelectedCurrencyUpdatable: AnyObject {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency)
}

protocol CurrencyControllerProviding: AnyObject {
  /// Returns the currency selected by toggling currency
  var selectedCurrencyCode: CurrencyCode { get }

  /// The fiat currency preferred by the user
  var fiatCurrency: CurrencyCode { get }

  var exchangeRates: ExchangeRates { get set }

  var currencyConverter: CurrencyConverter { get }
}

class CurrencyController: CurrencyControllerProviding {

  var fiatCurrency: CurrencyCode
  var exchangeRates: ExchangeRates
  var selectedCurrency: SelectedCurrency

  init(fiatCurrency: CurrencyCode,
       selectedCurrency: SelectedCurrency = .fiat,
       exchangeRates: ExchangeRates = [:]) {
    self.fiatCurrency = fiatCurrency
    self.selectedCurrency = selectedCurrency
    self.exchangeRates = exchangeRates
  }

  var selectedCurrencyCode: CurrencyCode {
    switch selectedCurrency {
    case .BTC:  return .BTC
    case .fiat: return fiatCurrency
    }
  }

  var currencyPair: CurrencyPair {
    return CurrencyPair(primary: selectedCurrencyCode, secondary: convertedCurrencyCode, fiat: fiatCurrency)
  }

  var currencyConverter: CurrencyConverter {
    return CurrencyConverter(rates: exchangeRates, fromAmount: .zero, currencyPair: currencyPair)
  }

  private var convertedCurrencyCode: CurrencyCode {
    switch selectedCurrencyCode {
    case .BTC: return fiatCurrency
    default: return .BTC
    }
  }
}
