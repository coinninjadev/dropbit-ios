//
//  TransactionDetailCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionDetailCellViewModel: TransactionSummaryCellViewModel, TransactionDetailCellViewModelType {

  var memoIsShared: Bool
  var date: Date
  var onChainConfirmations: Int?
  var addressProvidedToSender: String?
  var encodedInvoice: String?
  var paymentIdIsValid: Bool
  var invitationStatus: InvitationStatus?

  var exchangeRatesWhenReceived: ExchangeRates = [.BTC: 1]

  init(object: TransactionDetailCellViewModelObject,
       selectedCurrency: SelectedCurrency,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       deviceCountryCode: Int) {
    self.memoIsShared = object.memoIsShared
    self.date = object.primaryDate
    self.onChainConfirmations = object.onChainConfirmations
    self.addressProvidedToSender = object.addressProvidedToSender
    self.encodedInvoice = object.encodedInvoice
    self.paymentIdIsValid = object.paymentIdIsValid
    self.invitationStatus = object.invitationStatus

    if let usdRate = object.usdExchangeRateWhenReceived {
      self.exchangeRatesWhenReceived[.USD] = usdRate
    }

    super.init(object: object,
               selectedCurrency: selectedCurrency,
               fiatCurrency: fiatCurrency,
               exchangeRates: exchangeRates,
               deviceCountryCode: deviceCountryCode)
  }

  func exchangeRateWhenReceived(forCurrency currency: CurrencyCode) -> Double? {
    return exchangeRatesWhenReceived[currency]
  }

}

protocol TransactionDetailCellViewModelObject: TransactionSummaryCellViewModelObject {

  var memoIsShared: Bool { get }
  var primaryDate: Date { get }
  var onChainConfirmations: Int? { get }
  var addressProvidedToSender: String? { get }
  var encodedInvoice: String? { get }
  var paymentIdIsValid: Bool { get }
  var invitationStatus: InvitationStatus? { get }
  var usdExchangeRateWhenReceived: Double? { get }

}

extension CKMTransaction: TransactionDetailCellViewModelObject {
  var memoIsShared: Bool {
    return sharedPayload?.sharingDesired ?? false
  }

  var primaryDate: Date {
    return date ?? invitation?.sentDate ?? Date()
  }

  var onChainConfirmations: Int? {
    return confirmations
  }

  var addressProvidedToSender: String? {
    return invitation?.addressProvidedToSender
  }

  var encodedInvoice: String? {
    return nil
  }

  var paymentIdIsValid: Bool {
    return txidIsActualTxid
  }

  var invitationStatus: InvitationStatus? {
    return invitation?.status
  }

  var usdExchangeRateWhenReceived: Double? {
    return dayAveragePrice?.doubleValue
  }

}
