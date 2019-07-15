//
//  ConfirmPaymentViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Contacts
import CNBitcoinKit

protocol ConfirmPaymentViewModelType: SendPaymentDataProvider {
  var address: String? { get }
  var contact: ContactType? { get }
  var rates: ExchangeRates { get }
  var sharedPayloadDTO: SharedPayloadDTO? { get }

  mutating func update(with transactionData: CNBTransactionData)
}

class ConfirmPaymentInviteViewModel: ConfirmPaymentViewModelType {

  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  let rates: ExchangeRates
  let sharedPayloadDTO: SharedPayloadDTO?

  var addressPublicKeyState: AddressPublicKeyState {
    return .invite
  }

  init(address: String?,
       contact: ContactType?,
       btcAmount: NSDecimalNumber?,
       primaryCurrency: CurrencyCode,
       rates: ExchangeRates,
       sharedPayloadDTO: SharedPayloadDTO?) {
    self.address = address
    self.contact = contact
    self.btcAmount = btcAmount
    self.primaryCurrency = primaryCurrency
    self.rates = rates
    self.sharedPayloadDTO = sharedPayloadDTO
  }

  mutating func update(with transactionData: CNBTransactionData) { }
}

class ConfirmPaymentViewModel: ConfirmPaymentViewModelType {

  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  var outgoingTransactionData: OutgoingTransactionData
  var rates: ExchangeRates

  var sharedPayloadDTO: SharedPayloadDTO? {
    return outgoingTransactionData.sharedPayloadDTO
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    outgoingTransactionData: OutgoingTransactionData,
    rates: ExchangeRates
    ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.outgoingTransactionData = outgoingTransactionData
    self.rates = rates
  }

  mutating func update(with transactionData: CNBTransactionData) {
    btcAmount = NSDecimalNumber(integerAmount: Int(transactionData.amount), currency: .BTC)
  }
}

struct FeeRates {
  let high: Double
  let medium: Double
  let low: Double

  init?(fees: Fees) {
    guard let high = fees[.best], let medium = fees[.better], let low = fees[.good] else { return nil }
    self.high = high
    self.medium = medium
    self.low = low
  }

  func rate(forType type: TransactionFeeType) -> Double {
    switch type {
    case .fast:   return high
    case .slow:   return medium
    case .cheap:  return low
    }
  }
}

struct TransactionFeeConfig {
  let adjustableFeesEnabled: Bool
  let defaultFeeType: TransactionFeeType
  init(prefs: PreferencesBrokerType) {
    self.adjustableFeesEnabled = prefs.adjustableFeesIsEnabled
    self.defaultFeeType = prefs.preferredTransactionFeeType
  }
}

enum ConfirmTransactionFeeModel {
  case standard(CNBTransactionData)
  case required(CNBTransactionData)
  case adjustable(AdjustableTransactionFeeViewModel)

  var transactionData: CNBTransactionData {
    switch self {
    case .standard(let txData), .required(let txData):
      return txData
    case .adjustable(let vm):
      return vm.applicableTransactionData
    }
  }

  var feeAmount: Int {
    return Int(transactionData.feeAmount)
  }

}
