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
  var fee: Int { get }
  var rates: ExchangeRates { get }
  var sharedPayloadDTO: SharedPayloadDTO? { get }
}

struct ConfirmPaymentInviteViewModel: ConfirmPaymentViewModelType {
  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  let primaryCurrency: CurrencyCode
  let fee: Int
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
  var fee: Int
  var outgoingTransactionData: OutgoingTransactionData
  var transactionData: CNBTransactionData
  var rates: ExchangeRates

  var sharedPayloadDTO: SharedPayloadDTO? {
    return outgoingTransactionData.sharedPayloadDTO
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    fee: Int,
    outgoingTransactionData: OutgoingTransactionData,
    transactionData: CNBTransactionData,
    rates: ExchangeRates
    ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.fee = fee
    self.outgoingTransactionData = outgoingTransactionData
    self.transactionData = transactionData
    self.rates = rates
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    outgoingTransactionData: OutgoingTransactionData,
    transactionData: CNBTransactionData,
    rates: ExchangeRates
  ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.fee = Int(transactionData.feeAmount)
    self.outgoingTransactionData = outgoingTransactionData
    self.transactionData = transactionData
    self.rates = rates
  }

}
