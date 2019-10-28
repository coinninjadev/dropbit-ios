//
//  DualAmountDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol DualAmountDisplayable {
  var fiatFormatter: CKCurrencyFormatter { get }
  var bitcoinFormatter: BitcoinFormatter { get }
  var satsFormatter: SatsFormatter { get }

  var fromAmount: NSDecimalNumber { get }
  var exchangeRates: ExchangeRates { get }
  var currencyPair: CurrencyPair { get }

  func selectedCurrency() -> SelectedCurrency
  func dualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels

  ///optional
  var primaryAttributes: StringAttributes { get }
  var secondaryAttributes: StringAttributes { get }
  var currencyConverter: CurrencyConverter { get }
}

extension DualAmountDisplayable {

  var primaryAttributes: StringAttributes {
    return [:]
  }

  var secondaryAttributes: StringAttributes {
    return [:]
  }

  var currencyConverter: CurrencyConverter {
    return CurrencyConverter(rates: exchangeRates,
                             fromAmount: fromAmount,
                             currencyPair: currencyPair)
  }

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
    let currency = currencyConverter.fiatCurrency
    return FiatFormatter(currency: currency, withSymbol: true)
  }

  var bitcoinFormatter: BitcoinFormatter {
    return BitcoinFormatter(symbolType: .image)
  }

  var satsFormatter: SatsFormatter {
    return SatsFormatter()
  }

  func dualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    return displayableDualAmountLabels(walletTxType: walletTxType)
  }

  fileprivate func displayableDualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    let converter = currencyConverter

    let btcIsPrimary = selectedCurrency() == .BTC
    let btcAttributes: StringAttributes = btcIsPrimary ? primaryAttributes : secondaryAttributes
    let fiatAttributes: StringAttributes = btcIsPrimary ? secondaryAttributes : primaryAttributes

    let btcText = attributedString(for: converter.btcAmount, currency: .BTC,
                                   attributes: btcAttributes, walletTxType: walletTxType)
    let fiatText = attributedString(for: converter.fiatAmount, currency: converter.fiatCurrency,
                                    attributes: fiatAttributes, walletTxType: walletTxType)

    if btcIsPrimary {
      return DualAmountLabels(primary: btcText, secondary: fiatText)
    } else {
      return DualAmountLabels(primary: fiatText, secondary: btcText)
    }
  }

  private func attributedString(for amount: NSDecimalNumber?,
                                currency: CurrencyCode,
                                attributes: StringAttributes,
                                walletTxType: WalletTransactionType) -> NSAttributedString? {
    guard let amount = amount else { return nil }
    let formatType = CurrencyFormatType(walletTxType: walletTxType, currency: currency)
    switch formatType {
    case .fiat:     return fiatFormatter.attributedString(from: amount, attributes: attributes)
    case .sats:     return satsFormatter.attributedString(from: amount, attributes: attributes)
    case .bitcoin:  return bitcoinFormatter.attributedString(from: amount, attributes: attributes)
    }
  }

}

protocol DualAmountEditable: DualAmountDisplayable {
  var editingIsActive: Bool { get }
  var maxPrimaryWidth: CGFloat { get }
  var standardPrimaryFontSize: CGFloat { get }
  var reducedPrimaryFontSize: CGFloat { get }
}

extension DualAmountEditable {

  var bitcoinSymbolFont: UIFont {
    return .bitcoinSymbolFont(primaryFont.pointSize)
  }

  var primaryFont: UIFont {
    (primaryAttributes[.font] as? UIFont) ?? .regular(10)
  }

  var bitcoinFormatter: BitcoinFormatter {
    if selectedCurrency() == .BTC {
      return BitcoinFormatter(symbolType: .string, symbolFont: bitcoinSymbolFont)
    } else {
      return BitcoinFormatter(symbolType: .image)
    }
  }

  func editableDualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    let displaybleLabels = displayableDualAmountLabels(walletTxType: walletTxType)
    var primaryText: NSAttributedString? = displaybleLabels.primary
    if fromAmount == .zero && editingIsActive {
      primaryText = primarySymbol(for: walletTxType)
    }

    let mutablePrimaryText = primaryText.flatMap { NSMutableAttributedString(attributedString: $0) }
    mutablePrimaryText?.decreaseSizeIfNecessary(to: reducedPrimaryFontSize, maxWidth: maxPrimaryWidth)

    return DualAmountLabels(primary: mutablePrimaryText, secondary: displaybleLabels.secondary)
  }

  func primarySymbol(for walletTxType: WalletTransactionType) -> NSAttributedString? {
    let primaryCurrency = selectedCurrency().code
    let primaryFormat = CurrencyFormatType(walletTxType: walletTxType, currency: primaryCurrency)

    var symbol: String?
    var attributes: StringAttributes = [:]
    switch primaryFormat {
    case .bitcoin:
      symbol = primaryFormat.currency.symbol
      attributes[.font] = bitcoinSymbolFont
    case .sats:
      symbol = primaryFormat.currency.integerSymbol(forAmount: fromAmount)
      attributes[.font] = UIFont.regular(primaryFont.pointSize)
    case .fiat:
      symbol = primaryFormat.currency.symbol
      attributes[.font] = UIFont.regular(primaryFont.pointSize)
    }

    return symbol.flatMap { NSAttributedString(string: $0, attributes: attributes) }
  }

}
