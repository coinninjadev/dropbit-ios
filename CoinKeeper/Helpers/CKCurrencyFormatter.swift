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

  static func string(for amount: NSDecimalNumber?,
                     currency: CurrencyCode,
                     walletTransactionType: WalletTransactionType) -> String? {
    guard let amount = amount else { return nil }
    if currency.isFiat {
      return FiatFormatter(currency: currency, withSymbol: true).string(fromDecimal: amount)
    } else {
      switch walletTransactionType {
      case .lightning:
        return SatsFormatter().string(fromDecimal: amount)
      case .onChain:
        return BitcoinFormatter(symbolType: .string).string(fromDecimal: amount)
      }
    }
  }

  static func attributedString(for amount: NSDecimalNumber?,
                               currency: CurrencyCode,
                               walletTransactionType: WalletTransactionType) -> NSAttributedString? {
    guard let amount = amount else { return nil }
    if currency.isFiat {
      return FiatFormatter(currency: currency, withSymbol: true).attributedString(from: amount)
    } else {
      switch walletTransactionType {
      case .lightning:
        return NSAttributedString(string: SatsFormatter().string(fromDecimal: amount) ?? "")
      case .onChain:
        return BitcoinFormatter(symbolType: .string).attributedString(from: amount)
      }
    }
  }

  func string(fromNumber number: NSNumber) -> String? {
    let decimalNumber = NSDecimalNumber(decimal: number.decimalValue)
    return string(fromDecimal: decimalNumber)
  }

  func decimalString(fromDecimal decimalNumber: NSDecimalNumber) -> String? {
    return numberFormatterWithoutSymbol(for: currency).string(from: decimalNumber)
  }

  func string(fromDecimal decimalNumber: NSDecimalNumber) -> String? {
    let amountString = decimalString(fromDecimal: decimalNumber) ?? ""

    var formattedString = amountString
    if symbolType == .string {
      formattedString = currency.symbol + amountString
    }

    if showNegativeSymbol, decimalNumber.isNegativeNumber {
      formattedString = "- " + formattedString
    }

    return formattedString
  }

  fileprivate func numberFormatterWithoutSymbol(for currency: CurrencyCode, asInteger: Bool = false) -> NumberFormatter {
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

  func attributedString(from amount: NSDecimalNumber, size: Int = defaultSize) -> NSAttributedString? {
    guard let amountString = decimalString(fromDecimal: amount),
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
    guard let numberString = stringWithoutSymbol(fromDecimal: decimalNumber) else { return nil }
    if let symbol = currency.integerSymbol {
      return numberString + symbol
    } else {
      return numberString
    }
  }

  func stringWithoutSymbol(fromDecimal decimalNumber: NSDecimalNumber) -> String? {
    let sats = decimalNumber.asFractionalUnits(of: .BTC)
    let integerDecimal = NSDecimalNumber(value: sats)
    let numberString = super.string(fromDecimal: integerDecimal) ?? ""

    return numberString
  }

}
