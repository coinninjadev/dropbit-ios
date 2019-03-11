//
//  CalculatorViewModel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 3/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

enum CalculatorViewModelChange {
  case append(digit: String)
  case decimal
  case backspace
  case currency(CurrencyCode)
  case exchangeRates(ExchangeRates)
  case reset
}

struct CalculatorViewLabels {
  let leftCurrencyButton: String
  let rightCurrencyButton: String
  let currentAmount: NSAttributedString
  let convertedAmount: NSAttributedString
}

protocol CalculatorViewModelProviding: class {

  /// Holds the current string of digits entered by user
  var currentAmountRawString: String { get set }

  /// Holds the currency selected by didTapUSD/BTC()
  var currentCurrencyCode: CurrencyCode { get set }

  var exchangeRates: ExchangeRates { get set }

  var currencyConverter: CurrencyConverter { get }

  func apply(_ change: CalculatorViewModelChange)

  var labels: CalculatorViewLabels { get }

  var currencyToggleConfig: CalculatorCurrencyToggleConfig { get }

}

class CalculatorViewModel: CalculatorViewModelProviding {

  var currentAmountRawString: String

  var currentCurrencyCode: CurrencyCode

  var exchangeRates: ExchangeRates = [:]

  init(currentAmountString: String, currentCurrencyCode: CurrencyCode, exchangeRates: ExchangeRates = [:]) {
    self.currentAmountRawString = currentAmountString
    self.currentCurrencyCode = currentCurrencyCode
    self.exchangeRates = exchangeRates
  }

  /// Creates a converter from the latest inputs and returns it.
  var currencyConverter: CurrencyConverter {
    return CurrencyConverter(rates: exchangeRates, fromAmount: currentAmount, fromCurrency: currentCurrencyCode, toCurrency: convertedCurrencyCode)
  }

  // swiftlint:disable:next cyclomatic_complexity
  func apply(_ change: CalculatorViewModelChange) {
    switch change {
    case .append(let digit):
      if canAppendDigit(digit) {
        currentAmountRawString += digit
      }

    case .decimal:
      if !currentAmountRawString.contains(decimalSeparator) {
        currentAmountRawString += decimalSeparator
      }

    case .backspace:
      if !currentAmountRawString.isEmpty {
        currentAmountRawString.removeLast()
        if let lastCharacter = currentAmountRawString.last, String(lastCharacter) == decimalSeparator {
          currentAmountRawString.removeLast() //remove decimal automatically if deleting last fractional digit
        }
      }

    case .currency(let code):
      if code != currentCurrencyCode {
        let amountStringToSwap = cleanedConvertedAmountString // important to get this before changing currentCurrencyCode
        currentCurrencyCode = code
        currentAmountRawString = amountStringToSwap
      }

    case .exchangeRates(let rates):
      self.exchangeRates = rates

    case .reset:
      currentAmountRawString = ""
    }
  }

  /// The view controller should use these returned labels to configure its view
  var labels: CalculatorViewLabels {
    // Return labels that reflect the updated variables

    let leftCurrencyTitle = currencyToggleLabel(for: .USD)
    let rightCurrencyTitle = currencyToggleLabel(for: .BTC)
    let convertedAmount = currencyConverter.attributedStringWithSymbol(forCurrency: convertedCurrencyCode)

    return CalculatorViewLabels(leftCurrencyButton: leftCurrencyTitle,
                                rightCurrencyButton: rightCurrencyTitle,
                                currentAmount: currentAmountAttributedString,
                                convertedAmount: convertedAmount ?? NSAttributedString())
  }

  var currencyToggleConfig: CalculatorCurrencyToggleConfig {
    return CalculatorCurrencyToggleConfig(leftButtonTitle: labels.leftCurrencyButton,
                                          rightButtonTitle: labels.rightCurrencyButton,
                                          selectedSegment: selectedCurrencySegment)
  }

  // MARK: - Private

  var convertedCurrencyCode: CurrencyCode {
    switch currentCurrencyCode {
    case .BTC:	return .USD
    case .USD:	return .BTC
    }
  }

  private var decimalSeparator: String {
    return Locale.current.decimalSeparator ??  "."
  }

  // MARK: - Amount values

  private var currentAmount: NSDecimalNumber {
    guard let possibleNumber = NSDecimalNumber(fromString: currentAmountRawString) else { return .zero }

    return possibleNumber
  }

  private var convertedAmount: NSDecimalNumber {
    return currencyConverter.convertedAmount() ?? .zero
  }

  // MARK: - Logic to check changes

  /**
   Can't check currentAmount.significantFractionalDecimalDigits because 0s don't count
   as significant until they are followed by another digit.
   */
  private func canAppendDigit(_ digit: String) -> Bool {
    let maxPlaces = currentCurrencyCode.decimalPlaces

    // count significant decimal digits for proposed string
    let potentialCurrentAmountString = currentAmountRawString + digit
    guard let potentialCurrentAmount = NSDecimalNumber(fromString: potentialCurrentAmountString) else { return false }
    let potentialSignificantDecimalPlaces = potentialCurrentAmount.significantFractionalDecimalDigits

    // check both conditions are met
    return (rawStringDecimalLength < maxPlaces && potentialSignificantDecimalPlaces <= maxPlaces)
  }

  // MARK: Evaluate decimal property

  private var rawStringDecimalComponent: String? {
    let numberComponents = currentAmountRawString.components(separatedBy: decimalSeparator)
    if numberComponents.count == 2, let decimalComponent = numberComponents.last {
      return decimalComponent
    } else {
      return nil
    }
  }

  private var rawStringDecimalLength: Int {
    return rawStringDecimalComponent?.count ?? 0
  }

  private var rawStringContainsDecimal: Bool {
    return currentAmountRawString.contains(decimalSeparator)
  }

  // MARK: - Currency toggle

  private var selectedCurrencySegment: CalculatorCurrencyToggleSegment {
    switch currentCurrencyCode {
    case .USD:	return .left
    case .BTC:	return .right
    }
  }

  // MARK: - Formatting

  /**
   - parameter withMinFractionDigits: use a minimum for fractional digits, default is true
   - parameter minFractionDigits: override the minFractionDigits, defaults to currencyCode.decimalPlaces
   */
  private func numberFormatter(for currencyCode: CurrencyCode, withMinFractionDigits: Bool = true, minFractionDigits: Int? = nil) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = .current //affects decimal and grouping separator
    formatter.currencySymbol = currencyCode.symbol
    formatter.numberStyle = .decimal

    let decimalPlaces = currencyCode.decimalPlaces
    formatter.maximumFractionDigits = decimalPlaces
    if withMinFractionDigits {
      formatter.minimumFractionDigits = minFractionDigits ?? decimalPlaces
    }

    return formatter
  }

  private func currencyToggleLabel(for currencyCode: CurrencyCode) -> String {
    switch currencyCode {
    case .BTC:	return "\u{20BF}  BITCOIN"
    case .USD:	return "$  USD"
    }
  }

  /// Used to prepare the formatted converted string to be swapped for the currentAmountRawString
  private var cleanedConvertedAmountString: String {
    let groupingSeparator = numberFormatter(for: convertedCurrencyCode).groupingSeparator ?? ""
    return convertedAmountFormatted.replacingOccurrences(of: groupingSeparator, with: "")
  }

  private var currentAmountAttributedString: NSAttributedString {
    let symbol = currentCurrencyCode.symbol
    let amount = currentAmountFormatted
    let symbolFont = Theme.Font.calculatorPrimarySymbol.font
    let amountFont = Theme.Font.calculatorPrimaryAmount.font

    let attributedString = NSMutableAttributedString(string: symbol + amount, attributes: [.foregroundColor: Theme.Color.darkBlueText.color])

    // symbol offset
    let maxOffset: Double = 18
    let charactersForMaxOffset: Double = 9
    let extraCharacters: Double = max(0, Double(attributedString.length) - charactersForMaxOffset)
    let adjustedOffset: Double = maxOffset - (extraCharacters / 2.0) // an approximate factor for adjusting the offset for each additional character
    let baselineOffset = NSNumber(value: max(6, adjustedOffset)) // min offset of 6

    // symbol attributes
    let symbolRange = NSRange(location: 0, length: symbol.count)
    attributedString.setAttributes([.font: symbolFont, .baselineOffset: baselineOffset], range: symbolRange)

    // amount attributes
    let amountRange = NSRange(location: symbol.count, length: amount.count)
    attributedString.setAttributes([.font: amountFont], range: amountRange)

    return attributedString
  }

  private var currentAmountFormatted: String {
    let currentAmountFormatter = numberFormatter(for: currentCurrencyCode,
                                                 withMinFractionDigits: rawStringContainsDecimal,
                                                 minFractionDigits: rawStringDecimalLength)

    let formattedAmount = currentAmountFormatter.string(from: currentAmount) ?? ""

    if rawStringContainsDecimal && !formattedAmount.contains(decimalSeparator) {
      //Append decimal to formatted value since the formatter won't include it
      //without additional digits, i.e. show "1." because they just tapped the decimal
      return formattedAmount + decimalSeparator

    } else {
      return formattedAmount
    }
  }

  private var convertedAmountMinimumFractionDigits: Int {
    if convertedAmount.significantFractionalDecimalDigits == 0 {
      return 0

    } else {
      switch convertedCurrencyCode {
      case .BTC:	return 0
      case .USD:	return 2
      }
    }
  }

  private var convertedAmountFormatted: String {
    let convertedAmountFormatter = numberFormatter(for: convertedCurrencyCode,
                                                   withMinFractionDigits: true,
                                                   minFractionDigits: convertedAmountMinimumFractionDigits)
    return convertedAmountFormatter.string(from: convertedAmount) ?? ""
  }

}
