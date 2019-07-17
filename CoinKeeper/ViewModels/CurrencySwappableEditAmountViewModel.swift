//
//  CurrencySwappableEditAmountViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol DualAmountDisplayable: CurrencyConverterProvider {
  var primaryCurrency: CurrencyCode { get }
}

extension DualAmountDisplayable {

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
    let currencyConverter = generateCurrencyConverter()

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

/// The object that should handle UI updates when the amount view model changes
protocol CurrencySwappableEditAmountViewModelDelegate: CurrencyValueDataSourceType {
  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidSwapCurrencies(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidUpdateExchangeRates(_ viewModel: CurrencySwappableEditAmountViewModel)
}

class CurrencySwappableEditAmountViewModel: NSObject, DualAmountDisplayable, ExchangeRateUpdateable {

  var rateManager: ExchangeRateManager
  var fromAmount: NSDecimalNumber
  var fromCurrency: CurrencyCode
  var toCurrency: CurrencyCode
  let fiatCurrency: CurrencyCode

  weak var delegate: CurrencySwappableEditAmountViewModelDelegate!

  var currencyValueManager: CurrencyValueDataSourceType? {
    return delegate
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    delegate.viewModelDidUpdateExchangeRates(self)
  }

  init(rateManager: ExchangeRateManager,
       primaryAmount: NSDecimalNumber,
       primaryCurrency: CurrencyCode,
       secondaryCurrency: CurrencyCode,
       fiatCurrency: CurrencyCode,
       delegate: CurrencySwappableEditAmountViewModelDelegate) {
    self.rateManager = rateManager
    self.fromAmount = primaryAmount
    self.fromCurrency = primaryCurrency
    self.toCurrency = secondaryCurrency
    self.fiatCurrency = fiatCurrency
    self.delegate = delegate
  }

  init(viewModel vm: CurrencySwappableEditAmountViewModel) {
    self.rateManager = vm.rateManager
    self.fromAmount = vm.primaryAmount
    self.fromCurrency = vm.primaryCurrency
    self.toCurrency = vm.secondaryCurrency
    self.fiatCurrency = vm.fiatCurrency
    self.delegate = vm.delegate
  }

  // Convenience getter/setter
  var primaryCurrency: CurrencyCode {
    get { return fromCurrency }
    set { fromCurrency = newValue }
  }

  var primaryAmount: NSDecimalNumber {
    get { return fromAmount }
    set { fromAmount = newValue }
  }

  var secondaryCurrency: CurrencyCode {
    get { return toCurrency }
    set { toCurrency = newValue }
  }

  func swapPrimaryCurrency() {
    let oldFromCurrency = fromCurrency
    fromCurrency = toCurrency
    toCurrency = oldFromCurrency
  }

  func updatePrimaryCurrency(to selectedCurrency: SelectedCurrency) {
    switch selectedCurrency {
    case .BTC:  primaryCurrency = .BTC
    case .fiat: primaryCurrency = fiatCurrency
    }
  }

  /// Formatted to work with text field editing across locales and currencies
  func primaryAmountInputText() -> String? {
    let converter = generateCurrencyConverter()
    let primaryAmount = converter.amount(forCurrency: primaryCurrency) ?? .zero
    let amountString = converter.amountStringWithoutSymbol(primaryAmount, primaryCurrency) ?? ""
    return primaryCurrency.symbol + amountString
  }

  /// Removes the currency symbol and thousands separator from the primary text, based on Locale.current
  private func sanitizedAmountString(_ rawText: String?) -> String? {
    return rawText?.removing(groupingSeparator: self.groupingSeparator,
                             currencySymbol: primaryCurrency.symbol)
  }

  /// Returns .zero for nil, empty, and other invalid strings.
  func sanitizedAmount(fromRawText rawText: String?) -> NSDecimalNumber {
    guard let textToSanitize = rawText,
      let sanitizedText = sanitizedAmountString(textToSanitize)
      else { return .zero }

    return NSDecimalNumber(fromString: sanitizedText) ?? .zero
  }

}

extension CurrencySwappableEditAmountViewModel: UITextFieldDelegate {

  @objc func primaryAmountTextFieldDidChange(_ textField: UITextField) {
    fromAmount = sanitizedAmount(fromRawText: textField.text)
    delegate.viewModelDidChangeAmount(self)
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    let amount = sanitizedAmount(fromRawText: textField.text)
    delegate.viewModelDidBeginEditingAmount(self)
    if amount == .zero {
      textField.text = primaryCurrency.symbol
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text, let swiftRange = Range(range, in: text), isNotDeletingOrEditingCurrencySymbol(for: text, in: range) else {
      return false
    }

    let finalString = text.replacingCharacters(in: swiftRange, with: string)
    return primaryAmountTextFieldShouldChangeCharacters(inProposedString: finalString)
  }

  private func primaryAmountTextFieldShouldChangeCharacters(inProposedString finalString: String) -> Bool {
    let splitByDecimalArray = finalString.components(separatedBy: decimalSeparator).dropFirst()

    if !splitByDecimalArray.isEmpty {
      guard splitByDecimalArray[1].count <= primaryCurrency.decimalPlaces else {
        return false
      }
    }

    guard finalString.count(of: decimalSeparatorCharacter) <= 1 else {
      return false
    }

    let requiredSymbolString = primaryCurrency.symbol
    guard finalString.contains(requiredSymbolString) else {
      return false
    }

    let trimmedFinal = finalString.removing(groupingSeparator: self.groupingSeparator, currencySymbol: requiredSymbolString)
    if trimmedFinal.isEmpty {
      return true // allow deletion of all digits by returning early
    }

    guard let newAmount = NSDecimalNumber(fromString: trimmedFinal) else { return false }

    guard newAmount.significantFractionalDecimalDigits <= primaryCurrency.decimalPlaces else {
      return false
    }


    return true
  }

  private func isNotDeletingOrEditingCurrencySymbol(for amount: String, in range: NSRange) -> Bool {
    return (amount != primaryCurrency.symbol || range.length == 0)
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    // Skip triggering changes/validation if textField is empty
    guard let text = textField.text, text.isNotEmpty else {
      return
    }

    delegate.viewModelDidEndEditingAmount(self)
  }

}
