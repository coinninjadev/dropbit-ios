//
//  CurrencyViewModel.swift
//  DropBit
//
//  Created by BJ Miller on 4/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencyViewModelProviding: AnyObject {
  /// Holds the currency selected by toggling currency
  var currentCurrencyCode: CurrencyCode { get set }

  var exchangeRates: ExchangeRates { get set }

  var currencyConverter: CurrencyConverter { get }
}

class CurrencyViewModel: CurrencyViewModelProviding {
  var currentCurrencyCode: CurrencyCode
  var exchangeRates: ExchangeRates

  init(currentCurrencyCode: CurrencyCode, exchangeRates: ExchangeRates = [:]) {
    self.currentCurrencyCode = currentCurrencyCode
    self.exchangeRates = exchangeRates
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
