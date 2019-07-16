//
//  CurrencySwappableEditAmountViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol DualAmountDisplayable {
  var currencyConverter: CurrencyConverter { get set }
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

class CurrencySwappableEditAmountViewModel: DualAmountDisplayable {
  var currencyConverter: CurrencyConverter

  init(currencyConverter: CurrencyConverter) {
    self.currencyConverter = currencyConverter
  }

  var primaryCurrency: CurrencyCode {
    get { return currencyConverter.fromCurrency }
    set { currencyConverter.fromCurrency = newValue }
  }

  func swapPrimaryCurrency() {
    let currentPrimary = primaryCurrency
    primaryCurrency = currencyConverter.otherCurrency(forCurrency: currentPrimary)
  }

  func updatePrimaryCurrency(to selectedCurrency: SelectedCurrency) {
    switch selectedCurrency {
    case .BTC:  primaryCurrency = .BTC
    case .fiat: primaryCurrency = .USD
    }
  }

  /// Formatted to work with text field editing across locales and currencies
  func primaryAmountInputText() -> String? {
    let primaryAmount = currencyConverter.amount(forCurrency: primaryCurrency) ?? .zero
    let amountString = currencyConverter.amountStringWithoutSymbol(primaryAmount, primaryCurrency) ?? ""
    return primaryCurrency.symbol + amountString
  }

}

protocol SendPaymentDataProvider {
  var btcAmount: NSDecimalNumber? { get }
  var primaryCurrency: CurrencyCode { get }
  var address: String? { get }
}
