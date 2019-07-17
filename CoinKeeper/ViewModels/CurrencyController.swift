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
}

protocol SelectedCurrencyUpdatable: AnyObject {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency)
}

protocol CurrencyControllerProviding: AnyObject {
  /// Holds the currency selected by toggling currency
  var currentCurrencyCode: CurrencyCode { get set }

  /// The fiat currency preferred by the user
  var fiatCurrency: CurrencyCode { get }

  var exchangeRates: ExchangeRates { get set }

  var currencyConverter: CurrencyConverter { get }
}

class CurrencyController: CurrencyControllerProviding {
  var currentCurrencyCode: CurrencyCode
  var fiatCurrency: CurrencyCode
  var exchangeRates: ExchangeRates
  var selectedCurrency: SelectedCurrency

  init(currentCurrencyCode: CurrencyCode,
       fiatCurrency: CurrencyCode,
       selectedCurrency: SelectedCurrency = .fiat,
       exchangeRates: ExchangeRates = [:]) {
    self.currentCurrencyCode = currentCurrencyCode
    self.fiatCurrency = fiatCurrency
    self.exchangeRates = exchangeRates
    self.selectedCurrency = selectedCurrency
  }

  var currencyConverter: CurrencyConverter {
    return CurrencyConverter(rates: exchangeRates, fromAmount: .zero, fromCurrency: currentCurrencyCode, toCurrency: convertedCurrencyCode)
  }

  private var convertedCurrencyCode: CurrencyCode {
    switch currentCurrencyCode {
    case .BTC: return .USD
    case .USD: return .BTC
    }
  }
}
