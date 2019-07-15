//
//  AmountCurrencySwappableViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol PaymentAmountDataProvider: AnyObject {
  var btcAmount: NSDecimalNumber? { get set }
  var primaryCurrency: CurrencyCode { get set }
}

extension PaymentAmountDataProvider {

  /// Pass in the current rates from the ExchangeRateManager
  func amountLabels(withRates rates: ExchangeRates, withSymbols: Bool) -> (primary: String?, secondary: NSAttributedString?) {
    let fromAmount = btcAmount ?? .zero
    let converter = CurrencyConverter(rates: rates, fromAmount: fromAmount, fromCurrency: .BTC, toCurrency: .USD)

    var primaryLabel = converter.amountStringWithSymbol(forCurrency: primaryCurrency)

    let secondaryCurrency = converter.otherCurrency(forCurrency: primaryCurrency)
    var secondaryLabel = secondaryCurrency.flatMap({ converter.attributedStringWithSymbol(forCurrency: $0) })

    if !withSymbols {
      primaryLabel = String(describing: converter.amount(forCurrency: primaryCurrency) ?? 0)
      secondaryLabel = secondaryCurrency.flatMap({ NSAttributedString(string: String(describing: converter.amount(forCurrency: $0) ?? 0)) })
    }

    return (primaryLabel, secondaryLabel)
  }

  /// Formatted to work with text field editing across locales and currencies
  func primaryAmountInputText(withRates rates: ExchangeRates) -> String? {
    let fromAmount = btcAmount ?? .zero
    let converter = CurrencyConverter(rates: rates, fromAmount: fromAmount, fromCurrency: .BTC, toCurrency: .USD)

    let primaryAmount = converter.amount(forCurrency: primaryCurrency) ?? .zero
    let amountString = converter.amountStringWithoutSymbol(primaryAmount, primaryCurrency) ?? ""

    return primaryCurrency.symbol + amountString
  }

}

protocol AmountCurrencySwappableViewModelType: PaymentAmountDataProvider { }

extension AmountCurrencySwappableViewModelType {

  var groupingSeparator: String {
    return Locale.current.groupingSeparator ?? ","
  }

  var decimalSeparator: String {
    return Locale.current.decimalSeparator ?? "."
  }

  var decimalSeparatorCharacter: Character {
    return decimalSeparator.first ?? "."
  }

  func togglePrimaryCurrency() {
    switch primaryCurrency {
    case .BTC: primaryCurrency = .USD
    case .USD: primaryCurrency = .BTC
    }
  }

  func updatePrimaryCurrency(to selectedCurrency: SelectedCurrency) {
    switch selectedCurrency {
    case .BTC: primaryCurrency = .BTC
    case .fiat: primaryCurrency = .USD
    }
  }

}

protocol SendPaymentDataProvider: PaymentAmountDataProvider {
  var address: String? { get }
}

protocol SendPaymentViewModelType: SendPaymentDataProvider, AmountCurrencySwappableViewModelType {

  var recipientParser: RecipientParserType { get }

  var address: String? { get }
  var btcAmount: NSDecimalNumber? { get set }
  var primaryCurrency: CurrencyCode { get set }
  var requiredFeeRate: Double? { get set }
  var memo: String? { get set }
  var sharedMemoDesired: Bool { get set }
  var sharedMemoAllowed: Bool { get set }
  var sendMaxTransactionData: CNBTransactionData? { get }
  func sendMax(with data: CNBTransactionData)

  var paymentRecipient: PaymentRecipient? { get set }

  func displayStyle(for recipient: PaymentRecipient?) -> RecipientDisplayStyle

  func displayRecipientName() -> String?
  func displayRecipientIdentity() -> String?

  var standardIgnoredOptions: CurrencyAmountValidationOptions { get }
  var invitationMaximumIgnoredOptions: CurrencyAmountValidationOptions { get }
}

extension SendPaymentViewModelType {

  var contact: ContactType? {
    if let recipient = paymentRecipient, case let .contact(contact) = recipient {
      return contact
    } else {
      return nil
    }
  }

  var shouldShowSharedMemoBox: Bool {
    if let recipient = paymentRecipient {
      switch recipient {
      case .btcAddress:     return false
      case .contact:        return true && sharedMemoAllowed
      case .phoneNumber:    return true && sharedMemoAllowed
      case .twitterContact: return true && sharedMemoAllowed
      }
    } else {
      return true && sharedMemoAllowed //show it by default
    }
  }

  var standardIgnoredOptions: CurrencyAmountValidationOptions {
    return [.invitationMaximum]
  }

  var invitationMaximumIgnoredOptions: CurrencyAmountValidationOptions {
    return [.usableBalance]
  }

}
