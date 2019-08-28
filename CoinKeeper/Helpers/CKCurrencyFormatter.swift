//
//  CKCurrencyFormatter.swift
//  DropBit
//
//  Created by Ben Winters on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class CKCurrencyFormatter {
  let currency: CurrencyCode
  var symbolType: CurrencySymbolType
  let showNegativeSymbol: Bool

  enum CurrencySymbolType {
    case string, attributed, none
  }

  ///Use a custom subclass instead of this formatter directly
  fileprivate init(currency: CurrencyCode,
                   symbolType: CurrencySymbolType,
                   showNegativeSymbol: Bool) {
    self.currency = currency
    self.symbolType = symbolType
    self.showNegativeSymbol = showNegativeSymbol
  }

  static func string(for amount: NSDecimalNumber?, currency: CurrencyCode) -> String? {
    guard let amount = amount else { return nil }
    if currency.isFiat {
      return FiatFormatter(currency: currency, withSymbol: true).string(fromDecimal: amount)
    } else {
      return BitcoinFormatter(symbolType: .string).string(fromDecimal: amount)
    }
  }

  static func attributedString(for amount: NSDecimalNumber?, currency: CurrencyCode, btcSymbolType: CurrencySymbolType) -> NSAttributedString? {
    guard let amount = amount else { return nil }
    if currency.isFiat {
      return FiatFormatter(currency: currency, withSymbol: true).attributedString(from: amount)
    } else {
      return BitcoinFormatter(symbolType: btcSymbolType).attributedString(from: amount)
    }
  }

  func string(fromNumber number: NSNumber) -> String? {
    let decimalNumber = NSDecimalNumber(decimal: number.decimalValue)
    return string(fromDecimal: decimalNumber)
  }

  func string(fromDecimal decimalNumber: NSDecimalNumber) -> String? {
    let decimalString = decimalFormatter(for: currency).string(from: decimalNumber) ?? ""

    var formattedString = decimalString
    if symbolType == .string {
      formattedString = currency.symbol + decimalString
    }

    if showNegativeSymbol, decimalNumber.isNegativeNumber {
      formattedString = "- " + formattedString
    }

    return formattedString
  }

  /// Formats the number without a currency symbol
  fileprivate func decimalFormatter(for currency: CurrencyCode, asInteger: Bool = false) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = asInteger ? 0 : currency.decimalPlaces
    if currency.requiresFullDecimalPlaces && !asInteger {
      formatter.minimumFractionDigits = currency.decimalPlaces
    }
    formatter.locale = Locale.current //determines grouping/decimal separators
    formatter.usesGroupingSeparator = true
    formatter.negativePrefix = ""
    formatter.negativeSuffix = ""
    formatter.numberStyle = .decimal
    return formatter
  }

}

class FiatFormatter: CKCurrencyFormatter {
  init(currency: CurrencyCode,
       withSymbol: Bool,
       showNegativeSymbol: Bool = false) {
    super.init(currency: currency,
               symbolType: withSymbol ? .string : .none,
               showNegativeSymbol: showNegativeSymbol)
  }

  func attributedString(from amount: NSDecimalNumber) -> NSAttributedString? {
    guard let str = string(fromDecimal: amount) else { return nil }
    return NSAttributedString(string: str)
  }

}

class BitcoinFormatter: CKCurrencyFormatter {

  init(symbolType: CurrencySymbolType) {
    super.init(currency: .BTC,
               symbolType: symbolType,
               showNegativeSymbol: false)
  }

  func attributedString(from amount: NSNumber, size: Int = defaultSize) -> NSAttributedString? {
    guard let amountString = string(fromNumber: amount),
      let symbol = attributedStringSymbol(ofSize: size)
      else { return nil }

    return symbol + NSAttributedString(string: amountString)
  }

  static var defaultSize: Int {
    return 20
  }

  private func attributedStringSymbol(ofSize size: Int) -> NSAttributedString? {
    let image = UIImage(named: "bitcoinLogo")
    let textAttribute = NSTextAttachment()
    textAttribute.image = image
    textAttribute.bounds = CGRect(x: -3, y: (-size / (BitcoinFormatter.defaultSize / 4)),
                                  width: size, height: size)

    return NSAttributedString(attachment: textAttribute)
  }

}

class SatsFormatter: CKCurrencyFormatter {
  init() {
    super.init(currency: .BTC,
               symbolType: .none,
               showNegativeSymbol: false)
  }

  override func string(fromDecimal decimalNumber: NSDecimalNumber) -> String? {
    let sats = decimalNumber.asFractionalUnits(of: .BTC)
    let integerDecimal = NSDecimalNumber(value: sats)
    let numberString = super.string(fromDecimal: integerDecimal) ?? ""
    if let symbol = currency.integerSymbol {
      return numberString + " \(symbol)"
    } else {
      return numberString
    }
  }

}
