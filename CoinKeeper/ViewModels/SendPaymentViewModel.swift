//
//  SendPaymentViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

enum PaymentRecipient {

  /// Associated value does not contain "bitcoin:"
  case btcAddress(String)

  case contact(ContactType)

  /// Manually entered, not set from Contacts. Associated value is digits only.
  case phoneNumber(GenericContact)

  case twitterContact(TwitterContactType)

  init?(parsedRecipient: CKParsedRecipient) {
    switch parsedRecipient {
    case .bitcoinURL(let url):
      guard let address = url.components.address else { return nil }
      self = .btcAddress(address)

    case .phoneNumber(let number):
      self = .phoneNumber(GenericContact(phoneNumber: number, formatted: ""))
    }
  }

}

/// Corresponds to the two types of input fields
enum RecipientDisplayStyle {
  case label
  case textField
}

class SendPaymentViewModel: CurrencySwappableEditAmountViewModel {

  var paymentRecipient: PaymentRecipient?
  var requiredFeeRate: Double?
  var sharedMemoDesired = true // default is true
  var sharedMemoAllowed = true // default is true
  var sendMaxTransactionData: CNBTransactionData?

  func sendMax(with data: CNBTransactionData) {
    self.sendMaxTransactionData = data
    self.primaryAmount = NSDecimalNumber(integerAmount: Int(data.amount), currency: .BTC)
    primaryCurrency = .BTC
    delegate.viewModelDidChangeAmount(self)
  }

  private var _memo: String?
  var memo: String? {
    // Allows downstream logic to assume that the optional string is not empty
    set { _memo = (newValue ?? "").isEmpty ? nil : newValue }
    get { return _memo }
  }

  var address: String? {
    if let recipient = paymentRecipient,
      case let .btcAddress(addr) = recipient {
      return addr
    } else {
      return nil
    }
  }

  let recipientParser: RecipientParserType = CKRecipientParser()

  init(qrCode: QRCode,
       rateManager: ExchangeRateManager,
       fiatCurrency: CurrencyCode,
       delegate: CurrencySwappableEditAmountViewModelDelegate) {
    let viewModel = CurrencySwappableEditAmountViewModel(rateManager: rateManager,
                                                         primaryAmount: qrCode.btcAmount ?? .zero,
                                                         primaryCurrency: .BTC,
                                                         secondaryCurrency: fiatCurrency,
                                                         fiatCurrency: fiatCurrency,
                                                         delegate: delegate)
    super.init(viewModel: viewModel)
    self.paymentRecipient = qrCode.address.flatMap { .btcAddress($0) }
    self.requiredFeeRate = nil
    self.memo = nil
  }

  init(editAmountViewModel: CurrencySwappableEditAmountViewModel,
       address: String? = nil, requiredFeeRate: Double? = nil, memo: String? = nil) {
    super.init(viewModel: editAmountViewModel)
    self.paymentRecipient = address.flatMap { .btcAddress($0) }
    self.requiredFeeRate = requiredFeeRate
    self.memo = memo
  }

  convenience init?(response: MerchantPaymentRequestResponse,
                    rateManager: ExchangeRateManager,
                    fiatCurrency: CurrencyCode,
                    delegate: CurrencySwappableEditAmountViewModelDelegate) {
    guard let output = response.outputs.first else { return nil }
    let btcAmount = NSDecimalNumber(integerAmount: output.amount, currency: .BTC)
    let viewModel = CurrencySwappableEditAmountViewModel(rateManager: rateManager,
                                                         primaryAmount: btcAmount,
                                                         primaryCurrency: .BTC,
                                                         secondaryCurrency: fiatCurrency,
                                                         fiatCurrency: fiatCurrency,
                                                         delegate: delegate)
    self.init(editAmountViewModel: viewModel,
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
    case .contact, .twitterContact:
      return .label
    }
  }

  func displayRecipientName() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .btcAddress: return nil
    case .contact(let contact): return contact.displayName
    case .twitterContact(let contact): return contact.displayName
    case .phoneNumber: return nil
    }
  }

  func displayRecipientIdentity() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .btcAddress: return nil
    case .contact(let contact):
      guard let phoneContact = contact as? PhoneContactType else { return nil }
      let formatter = CKPhoneNumberFormatter(format: .international)
      return (try? formatter.string(from: phoneContact.globalPhoneNumber)) ?? ""
    case .twitterContact(let contact):
      return contact.displayIdentity
    case .phoneNumber: return nil
    }
  }

  func displayStyle(for recipient: PaymentRecipient?) -> RecipientDisplayStyle {
    guard let r = recipient else { return .textField }
    switch r {
    case .btcAddress,
         .phoneNumber:    return .textField
    case .contact,
         .twitterContact: return .label
    }
  }

}
