//
//  CurrencySwappableAmountEditor.swift
//  DropBit
//
//  Created by Ben Winters on 7/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol DualAmountDisplayable {
  var currencyConverter: CurrencyConverter { get }
}

extension DualAmountDisplayable {

  var primaryCurrency: CurrencyCode {
    return currencyConverter.fromCurrency
  }

  var groupingSeparator: String {
    return Locale.current.groupingSeparator ?? ","
  }

  var decimalSeparator: String {
    return Locale.current.decimalSeparator ?? "."
  }

  var decimalSeparatorCharacter: Character {
    return decimalSeparator.first ?? "."
  }

  func amountLabels(withSymbols: Bool) -> DualAmountLabels {
    var primaryLabel = currencyConverter.amountStringWithSymbol(forCurrency: primaryCurrency)

    let secondaryCurrency = currencyConverter.otherCurrency(forCurrency: primaryCurrency)
    var secondaryLabel = currencyConverter.attributedStringWithSymbol(forCurrency: secondaryCurrency)

    if !withSymbols {
      let primaryAmount = currencyConverter.amount(forCurrency: primaryCurrency) ?? .zero
      primaryLabel = String(describing: primaryAmount)
      let secondaryAmount = currencyConverter.amount(forCurrency: secondaryCurrency) ?? .zero
      secondaryLabel = NSAttributedString(string: String(describing: secondaryAmount))
    }

    let primaryAsAttributed = primaryLabel.flatMap { NSAttributedString(string: $0) }

    return DualAmountLabels(primary: primaryAsAttributed, secondary: secondaryLabel)
  }

}

protocol CurrencySwappableAmountEditor: CurrencySwappableEditAmountViewDelegate, DualAmountDisplayable {

  var editAmountViewModel: CurrencySwappableEditAmountViewModel { get }
  var editAmountView: CurrencySwappableEditAmountView { get }
  var rateManager: ExchangeRateManager { get }

}

extension CurrencySwappableAmountEditor {

  func createCurrencyConverter(for decimal: NSDecimalNumber) -> CurrencyConverter {
    switch primaryCurrency {
    case .BTC:
      return CurrencyConverter(rates: rateManager.exchangeRates, fromAmount: decimal, fromCurrency: .BTC, toCurrency: .USD)
    default:
      return CurrencyConverter(rates: rateManager.exchangeRates, fromAmount: decimal, fromCurrency: .USD, toCurrency: .BTC)
    }
  }

  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView) {

  }

}

