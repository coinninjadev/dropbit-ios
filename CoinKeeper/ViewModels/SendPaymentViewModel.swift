//
//  SendPaymentViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

enum WalletTransactionType: String {
  case onChain
  case lightning

  var addressType: WalletAddressType {
    switch self {
    case .onChain:    return .btc
    case .lightning:  return .lightning
    }
  }
}

enum PaymentRecipient {

  /// Associated value may be either a BTC address or a lightning invoice.
  /// BTC address does not contain "bitcoin:".
  case destination(String)

  case contact(ContactType)

  /// Manually entered, not set from Contacts. Associated value is digits only.
  case phoneNumber(GenericContact)

  case twitterContact(TwitterContactType)

  init?(parsedRecipient: CKParsedRecipient) {
    switch parsedRecipient {
    case .bitcoinURL(let url):
      guard let address = url.components.address else { return nil }
      self = .destination(address)

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
  var sharedMemoDesired = true
  var sharedMemoAllowed = true
  var sendMaxTransactionData: CNBTransactionData?
  var walletTransactionType: WalletTransactionType

  func sendMax(with data: CNBTransactionData) {
    self.sendMaxTransactionData = data
    let btcAmount = NSDecimalNumber(integerAmount: Int(data.amount), currency: .BTC)
    setBTCAmountAsPrimary(btcAmount)
    delegate?.viewModelDidChangeAmount(self)
  }

  private var _memo: String?
  var memo: String? {
    // Allows downstream logic to assume that the optional string is not empty
    set { _memo = (newValue ?? "").isEmpty ? nil : newValue }
    get { return _memo }
  }

  var address: String? {
    if let recipient = paymentRecipient,
      case let .destination(addr) = recipient {
      return addr
    } else {
      return nil
    }
  }

  let recipientParser: RecipientParserType = CKRecipientParser()

  init(lightningInvoice: LNDecodePaymentRequestResponse,
       exchangeRates: ExchangeRates,
       currencyPair: CurrencyPair) {
    let currencyPair = CurrencyPair(primary: .BTC, fiat: currencyPair.fiat)
    let amount = NSDecimalNumber(integerAmount: lightningInvoice.numSatoshis ?? 0, currency: .BTC)
    let viewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                         primaryAmount: amount,
                                                         currencyPair: currencyPair,
                                                         delegate: nil)
    type = .lightning
    super.init(viewModel: viewModel)
    self.paymentRecipient = .lightning(lightningInvoice.destination)
    self.requiredFeeRate = nil
    self.memo = lightningInvoice.description
  }

  // delegate may be nil at init since the delegate is likely a view controller which requires this view model for its own creation
  init(qrCode: OnChainQRCode,
       walletTransactionType: WalletTransactionType,
       exchangeRates: ExchangeRates,
       currencyPair: CurrencyPair,
       delegate: CurrencySwappableEditAmountViewModelDelegate? = nil) {
    let currencyPair = CurrencyPair(primary: .BTC, fiat: currencyPair.fiat)
    let viewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                         primaryAmount: qrCode.btcAmount ?? .zero,
                                                         currencyPair: currencyPair,
                                                         delegate: delegate)
    self.walletTransactionType = walletTransactionType
    super.init(viewModel: viewModel)
    self.paymentRecipient = qrCode.address.flatMap { .destination($0) }
    self.requiredFeeRate = nil
    self.memo = nil
  }

  init(editAmountViewModel: CurrencySwappableEditAmountViewModel, walletTransactionType: WalletTransactionType,
       address: String? = nil, requiredFeeRate: Double? = nil, memo: String? = nil) {
    self.walletTransactionType = walletTransactionType
    super.init(viewModel: editAmountViewModel)
    self.paymentRecipient = address.flatMap { .destination($0) }
    self.requiredFeeRate = requiredFeeRate
    self.memo = memo
  }

  convenience init?(response: MerchantPaymentRequestResponse,
                    walletTransactionType: WalletTransactionType,
                    exchangeRates: ExchangeRates,
                    fiatCurrency: CurrencyCode,
                    delegate: CurrencySwappableEditAmountViewModelDelegate? = nil) {
    guard let output = response.outputs.first else { return nil }
    let btcAmount = NSDecimalNumber(integerAmount: output.amount, currency: .BTC)
    let currencyPair = CurrencyPair(primary: .BTC, secondary: fiatCurrency, fiat: fiatCurrency)
    let viewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                         primaryAmount: btcAmount,
                                                         currencyPair: currencyPair,
                                                         delegate: delegate)
    self.init(editAmountViewModel: viewModel,
              walletTransactionType: walletTransactionType,
              address: output.address,
              requiredFeeRate: response.requiredFeeRate,
              memo: response.memo)

    self.walletTransactionType = walletTransactionType
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
      case .destination:    return false
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

  var recipientDisplayStyle: RecipientDisplayStyle? {
    guard let recipient = paymentRecipient else {
      return .textField
    }

    switch recipient {
    case .phoneNumber, .destination:
      return .textField
    case .contact, .twitterContact:
      return .label
    }
  }

  func displayRecipientName() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .destination: return nil
    case .contact(let contact): return contact.displayName
    case .twitterContact(let contact): return contact.displayName
    case .phoneNumber: return nil
    case .lightning: return nil
    }
  }

  func displayRecipientIdentity() -> String? {
    guard let recipient = self.paymentRecipient else { return nil }
    switch recipient {
    case .destination: return nil
    case .contact(let contact):
      guard let phoneContact = contact as? PhoneContactType else { return nil }
      let formatter = CKPhoneNumberFormatter(format: .international)
      return (try? formatter.string(from: phoneContact.globalPhoneNumber)) ?? ""
    case .twitterContact(let contact):
      return contact.displayIdentity
    case .phoneNumber, .lightning: return nil
    }
  }

  func displayStyle(for recipient: PaymentRecipient?) -> RecipientDisplayStyle {
    guard let r = recipient else { return .textField }
    switch r {
    case .destination,
         .phoneNumber:    return .textField
    case .contact,
         .twitterContact: return .label
    }
  }

}
