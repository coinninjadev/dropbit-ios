//
//  SendPaymentViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

enum PaymentRecipient {

  /// Associated value does not contain "bitcoin:"
  case btcAddress(String)

  case contact(ContactType)

  /// Manually entered, not set from Contacts. Associated value is digits only.
  case phoneNumber(GenericContact)

  init?(parsedRecipient: CKParsedRecipient) {
    switch parsedRecipient {
    case .bitcoinURL(let url):
      guard let address = url.components.address else { return nil }
      self = .btcAddress(address)

    case .phoneNumber(let number):
      self = .phoneNumber(GenericContact(phoneNumber: number, hash: "", formatted: ""))
    }
  }

}

/// Corresponds to the two types of input fields
enum RecipientDisplayStyle {
  case label
  case textField
}

protocol SendPaymentViewModelType: SendPaymentDataProvider {

  var recipientParser: RecipientParserType { get }

  var address: String? { get }
  var btcAmount: NSDecimalNumber? { get set }
  var primaryCurrency: CurrencyCode { get set }
  var requiredFeeRate: Double? { get set }
  var memo: String? { get set }
  var sharedMemoDesired: Bool { get set }
  var sharedMemoAllowed: Bool { get set }

  var paymentRecipient: PaymentRecipient? { get set }

  func displayStyle(for recipient: PaymentRecipient?) -> RecipientDisplayStyle

  func displayRecipientName() -> String?
  func displayRecipientNumber() -> String?
}

extension SendPaymentViewModelType {

  // State-independent values
  var groupingSeparator: String {
    return Locale.current.groupingSeparator ?? ","
  }

  var decimalSeparator: String {
    return Locale.current.decimalSeparator ?? "."
  }

  var decimalSeparatorCharacter: Character {
    return decimalSeparator.first ?? "."
  }

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
      case .btcAddress:   return false
      case .contact:      return true && sharedMemoAllowed
      case .phoneNumber:  return true && sharedMemoAllowed
      }
    } else {
      return true && sharedMemoAllowed //show it by default
    }
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

struct SendPaymentViewModel: SendPaymentViewModelType {

  var paymentRecipient: PaymentRecipient?
  var btcAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  var requiredFeeRate: Double?
  var sharedMemoDesired = true // default is true
  var sharedMemoAllowed = true // default is true

  private var _memo: String?
  var memo: String? {
    set { // Allows downstream logic to assume that the optional string is not empty
      let newMemo = (newValue ?? "").isEmpty ? nil : newValue
      _memo = newMemo
    }
    get {
      return _memo
    }
  }

  var address: String? {
    if let recipient = paymentRecipient,
      case let .btcAddress(addr) = recipient {
      return addr
    } else {
      return nil
    }
  }

  let recipientParser: RecipientParserType

  init(qrCode: QRCode, primaryCurrency: CurrencyCode, parser: RecipientParserType) {
    self.recipientParser = parser
    self.paymentRecipient = qrCode.address.flatMap { .btcAddress($0) }
    self.btcAmount = qrCode.btcAmount
    self.primaryCurrency = primaryCurrency
    self.requiredFeeRate = nil
    self.memo = nil
  }

  init(btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode, parser: RecipientParserType,
       address: String? = nil, requiredFeeRate: Double? = nil, memo: String? = nil) {
    self.recipientParser = parser
    self.paymentRecipient = address.flatMap { .btcAddress($0) }
    self.btcAmount = btcAmount
    self.primaryCurrency = primaryCurrency
    self.requiredFeeRate = requiredFeeRate
    self.memo = memo
  }

  init?(response: MerchantPaymentRequestResponse, parser: RecipientParserType) {
    guard let output = response.outputs.first else { return nil }
    let amount = NSDecimalNumber(integerAmount: output.amount, currency: .BTC)
    self.init(btcAmount: amount,
              primaryCurrency: .BTC,
              parser: parser,
              address: output.address,
              requiredFeeRate: response.requiredFeeRate,
              memo: response.memo)
  }

  var recipientDisplayStyle: RecipientDisplayStyle? {
    guard let recipient = paymentRecipient else {
      return .textField
    }

    switch recipient {
    case .phoneNumber, .btcAddress:
      return .textField
    case .contact:
      return .label
    }
  }

  func displayRecipientName() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .btcAddress: return nil
    case .contact(let contact): return contact.displayName
    case .phoneNumber: return nil
    }
  }

  func displayRecipientNumber() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .btcAddress: return nil
    case .contact(let contact):
      let formatter = CKPhoneNumberFormatter(kit: PhoneNumberKit(), format: .international)
      return (try? formatter.string(from: contact.globalPhoneNumber)) ?? ""
    case .phoneNumber: return nil
    }
  }

  func displayStyle(for recipient: PaymentRecipient?) -> RecipientDisplayStyle {
    guard let r = recipient else { return .textField }
    switch r {
    case .btcAddress,
         .phoneNumber:  return .textField
    case .contact:      return .label
    }
  }

}
