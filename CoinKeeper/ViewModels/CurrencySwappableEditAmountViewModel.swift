//
//  CurrencySwappableEditAmountViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol DualAmountEditable: DualAmountDisplayable {

}

extension DualAmountEditable {

  var bitcoinFormatter: BitcoinFormatter {
    let symbolType: CurrencySymbolType = selectedCurrency() == .BTC ? .string : .image
    return BitcoinFormatter(symbolType: symbolType)
  }

  func editableDualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    let displaybleLabels = dualAmountLabels(walletTxType: walletTxType)
    var primaryText: NSAttributedString? = displaybleLabels.primary
    if fromAmount == .zero {
      primaryText = primarySymbol(for: walletTxType)
    }

    return DualAmountLabels(primary: primaryText, secondary: displaybleLabels.secondary)
  }

  func primarySymbol(for walletTxType: WalletTransactionType) -> NSAttributedString? {
    let primaryCurrency = selectedCurrency().code

    switch walletTxType {
    case .lightning:
      if primaryCurrency == .USD {
        return primaryCurrency.attributedSymbol
      } else {
        return primaryCurrency.attributedIntegerSymbol(forAmount: fromAmount)
      }
    case .onChain:
      return primaryCurrency.attributedSymbol
    }
  }

}

protocol DualAmountDisplayable: CurrencyConverterProvider {
  var fiatFormatter: CKCurrencyFormatter { get }
  var bitcoinFormatter: BitcoinFormatter { get }
  var satsFormatter: SatsFormatter { get }
  func selectedCurrency() -> SelectedCurrency
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

  var fiatFormatter: CKCurrencyFormatter {
    let currency = generateCurrencyConverter().fiatCurrency
    return FiatFormatter(currency: currency, withSymbol: true)
  }

  var bitcoinFormatter: BitcoinFormatter {
    return BitcoinFormatter(symbolType: .image)
  }

  var satsFormatter: SatsFormatter {
    return SatsFormatter()
  }

  /// hidePrimaryZero will return the currency symbol only if primary amount is zero, useful during editing
  func dualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    let converter = generateCurrencyConverter()
    let btcText = attributedString(for: converter.btcAmount, currency: .BTC, walletTxType: walletTxType)
    let fiatText = attributedString(for: converter.fiatAmount, currency: converter.fiatCurrency, walletTxType: walletTxType)

    switch selectedCurrency() {
    case .BTC:  return DualAmountLabels(primary: btcText, secondary: fiatText)
    case .fiat: return DualAmountLabels(primary: fiatText, secondary: btcText)
    }
  }

  private func attributedString(for amount: NSDecimalNumber?,
                                currency: CurrencyCode,
                                walletTxType: WalletTransactionType) -> NSAttributedString? {
    guard let amount = amount else { return nil }
    if currency.isFiat {
      return fiatFormatter.attributedString(from: amount)
    } else {
      switch walletTxType {
      case .lightning:
        return satsFormatter.attributedString(from: amount)
      case .onChain:
        return bitcoinFormatter.attributedString(from: amount)
      }
    }
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
  var walletTransactionType: WalletTransactionType

  weak var delegate: CurrencySwappableEditAmountViewModelDelegate?

  init(exchangeRates: ExchangeRates,
       primaryAmount: NSDecimalNumber,
       walletTransactionType: WalletTransactionType,
       currencyPair: CurrencyPair,
       delegate: CurrencySwappableEditAmountViewModelDelegate? = nil) {
    self.exchangeRates = exchangeRates
    self.walletTransactionType = walletTransactionType
    self.fromAmount = primaryAmount
    self.fromCurrency = currencyPair.primary
    self.toCurrency = currencyPair.secondary
    self.fiatCurrency = currencyPair.fiat
    self.delegate = delegate
  }

  init(viewModel vm: CurrencySwappableEditAmountViewModel) {
    self.exchangeRates = vm.exchangeRates
    self.fromAmount = vm.primaryAmount
    self.walletTransactionType = vm.walletTransactionType
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

  func selectedCurrency() -> SelectedCurrency {
    return fromCurrency.isFiat ? .fiat : .BTC
  }

  static func emptyInstance() -> CurrencySwappableEditAmountViewModel {
    let currencyPair = CurrencyPair(primary: .BTC, fiat: .USD)
    return CurrencySwappableEditAmountViewModel(exchangeRates: [:],
                                                primaryAmount: 0,
                                                walletTransactionType: .onChain,
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

  /// Removes the currency symbol and thousands separator from the primary text, based on Locale.current
  func sanitizedAmountString(_ rawText: String?) -> String? {
    return rawText?.removingNonDecimalCharacters(keepingCharactersIn: decimalSeparator)
  }

  /// Returns .zero for nil, empty, and other invalid strings.
  func sanitizedAmount(fromRawText rawText: String?) -> NSDecimalNumber {
    guard let textToSanitize = rawText,
      let sanitizedText = sanitizedAmountString(textToSanitize)
      else { return .zero }

    var amount = NSDecimalNumber(fromString: sanitizedText) ?? .zero

    if walletTransactionType == .lightning && primaryCurrency == .BTC {
      amount = NSDecimalNumber(integerAmount: amount.intValue, currency: .BTC)
    }

    return amount
  }

}

extension CurrencySwappableEditAmountViewModel: UITextFieldDelegate {

  @objc func primaryAmountTextFieldDidChange(_ textField: UITextField) {
    fromAmount = sanitizedAmount(fromRawText: textField.text)
    delegate?.viewModelDidChangeAmount(self)
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if fromAmount == .zero {
      if walletTransactionType == .lightning && primaryCurrency == .BTC {
        textField.text = fromCurrency.integerSymbol(forAmount: sanitizedAmount(fromRawText: textField.text))
      } else {
        textField.text = fromCurrency.symbol
      }
    }

    delegate?.viewModelDidBeginEditingAmount(self)
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if fromAmount == .zero {
      textField.attributedText = dualAmountLabels(walletTxType: walletTransactionType).primary
    }
    delegate?.viewModelDidEndEditingAmount(self)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text, isNotDeletingOrEditingCurrencySymbol(for: text, in: range) else { //let swiftRange = Range(range, in: text),
      return false
    }

    let currentSanitizedAmountString = sanitizedAmountString(textField.text) ?? ""

    let newString: String
    if string.isEmpty {
      newString = String(currentSanitizedAmountString.dropLast())
    } else {
      newString = currentSanitizedAmountString + string
    }

    self.primaryAmount = NSDecimalNumber(fromString: String(newString)) ?? .zero

    delegate?.viewModelDidChangeAmount(self)

//    let finalString = text.replacingCharacters(in: swiftRange, with: string)
//    let splitByDecimalArray = finalString.components(separatedBy: decimalSeparator).dropFirst()
//
//    if !splitByDecimalArray.isEmpty {
//      guard splitByDecimalArray[1].count <= primaryCurrency.decimalPlaces else {
//        return false
//      }
//    }
//
//    guard finalString.count(of: decimalSeparatorCharacter) <= 1 else {
//      return false
//    }
//
//    let requiredSymbolString = primaryCurrency.symbol
//    guard finalString.contains(requiredSymbolString) ||
//      finalString.contains(primaryCurrency.integerSymbol(forAmount: sanitizedAmount(fromRawText: textField.text)) ?? "") else {
//      return false
//    }
//
//    var symbolsToRemove = [requiredSymbolString]
//    if let integerSymbol = primaryCurrency.integerSymbol(forAmount: sanitizedAmount(fromRawText: textField.text)) {
//      symbolsToRemove.append(integerSymbol)
//    }
//
//    let trimmedFinal = finalString.removing(groupingSeparator: self.groupingSeparator, currencySymbols: symbolsToRemove)
//    if trimmedFinal.isEmpty {
//      return true // allow deletion of all digits by returning early
//    }
//
//    guard let newAmount = NSDecimalNumber(fromString: trimmedFinal) else { return false }
//
//    guard newAmount.significantFractionalDecimalDigits <= primaryCurrency.decimalPlaces else {
//      return false
//    }

    return false
  }

  private func isNotDeletingOrEditingCurrencySymbol(for amount: String, in range: NSRange) -> Bool {
    return (amount != primaryCurrency.symbol ||
      amount != primaryCurrency.integerSymbol(forAmount: sanitizedAmount(fromRawText: amount)))
  }

}
