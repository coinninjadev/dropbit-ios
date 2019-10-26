//
//  DualAmountDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol DualAmountEditable: DualAmountDisplayable {
  var editingIsActive: Bool { get }
}

extension DualAmountEditable {

  var standardSymbolSize: CGFloat {
    return 30
  }

  var bitcoinSymbolFont: UIFont {
    return .bitcoinSymbolFont(standardSymbolSize)
  }

  var standardSymbolFont: UIFont {
    return .regular(standardSymbolSize)
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

    return DualAmountLabels(primary: primaryText, secondary: displaybleLabels.secondary)
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
      attributes[.font] = UIFont.regular(primaryFontSize)
    case .fiat:
      symbol = primaryFormat.currency.symbol
      attributes[.font] = UIFont.regular(primaryFontSize)
    }

    return symbol.flatMap { NSAttributedString(string: $0, attributes: attributes) }
  }

}

protocol DualAmountDisplayable: CurrencyConverterProvider {
  var fiatFormatter: CKCurrencyFormatter { get }
  var bitcoinFormatter: BitcoinFormatter { get }
  var satsFormatter: SatsFormatter { get }
  func selectedCurrency() -> SelectedCurrency
  func dualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels

  ///optional
  var primaryAttributes: StringAttributes { get }
  var secondaryAttributes: StringAttributes { get }
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

  func dualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    return displayableDualAmountLabels(walletTxType: walletTxType)
  }

  var primaryAttributes: StringAttributes {
    return [:]
  }

  var secondaryAttributes: StringAttributes {
    return [:]
  }

  fileprivate func displayableDualAmountLabels(walletTxType: WalletTransactionType) -> DualAmountLabels {
    let converter = generateCurrencyConverter()

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
