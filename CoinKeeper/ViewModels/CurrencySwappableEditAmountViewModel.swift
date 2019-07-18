//
//  CurrencySwappableEditAmountViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol DualAmountDisplayable: CurrencyConverterProvider { }

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

  func dualAmountLabels(withSymbols: Bool) -> DualAmountLabels {
    let currencyConverter = generateCurrencyConverter()
    let primaryCurrency = currencyPair.primary

    var primaryLabel = currencyConverter.amountStringWithSymbol(forCurrency: primaryCurrency)

    let secondaryCurrency = currencyConverter.otherCurrency(forCurrency: primaryCurrency)
    var secondaryLabel = currencyConverter.attributedStringWithSymbol(forCurrency: secondaryCurrency)

    if !withSymbols {
      let primaryAmount = currencyConverter.amount(forCurrency: primaryCurrency) ?? .zero
      primaryLabel = String(describing: primaryAmount)
      let secondaryAmount = currencyConverter.amount(forCurrency: secondaryCurrency) ?? .zero
      secondaryLabel = NSAttributedString(string: String(describing: secondaryAmount))
    }

    return DualAmountLabels(primary: primaryLabel, secondary: secondaryLabel)
  }

}

/// The object that should handle UI updates when the amount view model changes
protocol CurrencySwappableEditAmountViewModelDelegate: AnyObject {
  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidSwapCurrencies(_ viewModel: CurrencySwappableEditAmountViewModel)
}

/// Convenient for passing these values and initialization.
/// Either primary or secondary must be BTC and the other must be fiat.
struct CurrencyPair {
  let primary: CurrencyCode
  let secondary: CurrencyCode
  let fiat: CurrencyCode

  init(primary: CurrencyCode, secondary: CurrencyCode, fiat: CurrencyCode) {
    self.primary = primary
    self.secondary = secondary
    self.fiat = fiat
  }

  init(btcPrimaryWith currencyController: CurrencyController) {
    let fiat = currencyController.fiatCurrency
    self.init(primary: .BTC, secondary: fiat, fiat: fiat)
  }

  init(primary: CurrencyCode, fiat: CurrencyCode) {
    self.primary = primary
    self.fiat = fiat
    self.secondary = (primary == .BTC) ? fiat : .BTC
  }
}

class CurrencySwappableEditAmountViewModel: NSObject, DualAmountDisplayable {

  var exchangeRates: ExchangeRates
  var fromAmount: NSDecimalNumber
  var fromCurrency: CurrencyCode
  var toCurrency: CurrencyCode
  let fiatCurrency: CurrencyCode

  weak var delegate: CurrencySwappableEditAmountViewModelDelegate?

  init(exchangeRates: ExchangeRates,
       primaryAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       delegate: CurrencySwappableEditAmountViewModelDelegate? = nil) {
    self.exchangeRates = exchangeRates
    self.fromAmount = primaryAmount
    self.fromCurrency = currencyPair.primary
    self.toCurrency = currencyPair.secondary
    self.fiatCurrency = currencyPair.fiat
    self.delegate = delegate
  }

  init(viewModel vm: CurrencySwappableEditAmountViewModel) {
    self.exchangeRates = vm.exchangeRates
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

  var currencyPair: CurrencyPair {
    return CurrencyPair(primary: fromCurrency, secondary: toCurrency, fiat: fiatCurrency)
  }

  func swapPrimaryCurrency() {
    let oldToAmount = generateCurrencyConverter().convertedAmount() ?? .zero
    self.fromAmount = oldToAmount
    let oldFromCurrency = fromCurrency
    fromCurrency = toCurrency
    toCurrency = oldFromCurrency
  }

  func setBTCAmountAsPrimary(_ amount: NSDecimalNumber) {
    self.fromAmount = amount
    self.primaryCurrency = .BTC
    self.secondaryCurrency = self.fiatCurrency
  }

  var btcAmount: NSDecimalNumber {
    let converter = generateCurrencyConverter()
    return converter.btcAmount
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
    delegate?.viewModelDidChangeAmount(self)
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    let amount = sanitizedAmount(fromRawText: textField.text)
    delegate?.viewModelDidBeginEditingAmount(self)
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

    delegate?.viewModelDidEndEditingAmount(self)
  }

}
