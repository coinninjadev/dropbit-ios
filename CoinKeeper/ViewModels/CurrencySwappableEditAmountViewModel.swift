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

  /// hidePrimaryZero will return the currency symbol only if primary amount is zero, useful during editing
  func dualAmountLabels(hidePrimaryZero: Bool = false) -> DualAmountLabels {
    let converter = generateCurrencyConverter()
    return dualAmountLabels(withConverter: converter)
  }

  func dualAmountLabels(
    withConverter currencyConverter: CurrencyConverter,
    withSymbols: Bool = true,
    hidePrimaryZero: Bool = false) -> DualAmountLabels {

    let primaryCurrency = currencyPair.primary
    let secondaryCurrency = currencyPair.secondary
    let primaryAmount = currencyConverter.amount(forCurrency: primaryCurrency) ?? .zero
    let secondaryAmount = currencyConverter.amount(forCurrency: secondaryCurrency) ?? .zero

    var primaryText = CKCurrencyFormatter.string(for: primaryAmount, currency: primaryCurrency)
    if hidePrimaryZero && fromAmount == .zero {
      primaryText = primaryCurrency.symbol
    }

    let secondaryAttributed = CKCurrencyFormatter.attributedString(for: secondaryAmount,
                                                                   currency: secondaryCurrency,
                                                                   btcSymbolType: .attributed)

    return DualAmountLabels(primary: primaryText, secondary: secondaryAttributed)
  }

}

/// The object that should handle UI updates when the amount view model changes
protocol CurrencySwappableEditAmountViewModelDelegate: AnyObject {
  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel)
  func viewModelDidSwapCurrencies(_ viewModel: CurrencySwappableEditAmountViewModel)
}

extension CurrencySwappableEditAmountViewModelDelegate {
  // Optional delegate methods
  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) { }
  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) { }
  func viewModelDidSwapCurrencies(_ viewModel: CurrencySwappableEditAmountViewModel) { }
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
  var fiatCurrency: CurrencyCode

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
    get { return CurrencyPair(primary: fromCurrency, secondary: toCurrency, fiat: fiatCurrency) }
    set {
      fromCurrency = newValue.primary
      toCurrency = newValue.secondary
      fiatCurrency = newValue.fiat
    }
  }

  static func emptyInstance() -> CurrencySwappableEditAmountViewModel {
    let currencyPair = CurrencyPair(primary: .BTC, fiat: .USD)
    return CurrencySwappableEditAmountViewModel(exchangeRates: [:],
                                                primaryAmount: 0,
                                                currencyPair: currencyPair)
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

  var btcIsPrimary: Bool {
    return primaryCurrency == .BTC
  }

  /// Formatted to work with text field editing across locales and currencies
  func primaryAmountInputText() -> String? {
    let converter = generateCurrencyConverter()
    let primaryAmount = converter.amount(forCurrency: primaryCurrency) ?? .zero
    if btcIsPrimary {
      return BitcoinFormatter(symbolType: .string).string(fromDecimal: primaryAmount)
    } else {
      return FiatFormatter(currency: primaryCurrency, withSymbol: true).string(fromDecimal: primaryAmount)
    }
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
    if fromAmount == .zero {
      textField.text = fromCurrency.symbol
    }

    delegate?.viewModelDidBeginEditingAmount(self)
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if fromAmount == .zero {
      textField.text = dualAmountLabels().primary
    }
    delegate?.viewModelDidEndEditingAmount(self)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text, let swiftRange = Range(range, in: text), isNotDeletingOrEditingCurrencySymbol(for: text, in: range) else {
      return false
    }

    let finalString = text.replacingCharacters(in: swiftRange, with: string)
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

}
