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
  var btcAmount: NSDecimalNumber? { get }
  var primaryCurrency: CurrencyCode { get }
  var rates: ExchangeRates { get }
  var sharedPayloadDTO: SharedPayloadDTO? { get }
  var feeModel: ConfirmTransactionFeeModel { get }
}

struct ConfirmPaymentInviteViewModel: ConfirmPaymentViewModelType {
  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  let primaryCurrency: CurrencyCode
  let feeModel: ConfirmTransactionFeeModel
  let rates: ExchangeRates
  let sharedPayloadDTO: SharedPayloadDTO?

  var addressPublicKeyState: AddressPublicKeyState {
    return .invite
  }
}

struct ConfirmPaymentViewModel: ConfirmPaymentViewModelType {

  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  let feeModel: ConfirmTransactionFeeModel
  var outgoingTransactionData: OutgoingTransactionData
  var rates: ExchangeRates

  var transactionData: CNBTransactionData {
    return feeModel.transactionData
  }

  var sharedPayloadDTO: SharedPayloadDTO? {
    return outgoingTransactionData.sharedPayloadDTO
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    feeModel: ConfirmTransactionFeeModel,
    outgoingTransactionData: OutgoingTransactionData,
    rates: ExchangeRates
    ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.feeModel = feeModel
    self.outgoingTransactionData = outgoingTransactionData
    self.rates = rates
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    outgoingTransactionData: OutgoingTransactionData,
    feeModel: ConfirmTransactionFeeModel,
    rates: ExchangeRates
  ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.outgoingTransactionData = outgoingTransactionData
    self.feeModel = feeModel
    self.rates = rates
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
