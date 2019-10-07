//
//  TransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PhoneNumberKit
import CNBitcoinKit

/*
class OldTransactionSummaryCellViewModel {

  var counterpartyDescription: String
  var receiverAddress: String?
  var confirmations: Int
  var isConfirmed: Bool
  var invitationStatus: InvitationStatus?
  var broadcastFailed: Bool
  var isIncoming: Bool
  var sentAmountAtCurrentConverter: CurrencyConverter
  var btcReceived: NSDecimalNumber?
  var netWalletAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  var date: Date?
  var memo: String
  var counterpartyAvatar: UIImage?

  private(set) var transaction: CKMTransaction?
  private(set) var walletEntry: CKMWalletEntry?

  init(
    transaction: CKMTransaction,
    rates: ExchangeRates,
    primaryCurrency: CurrencyCode,
    deviceCountryCode: Int?
    ) {
    self.transaction = transaction
    self.broadcastFailed = transaction.broadcastFailed
    let counterpartyAddress = "" //transaction.counterpartyAddressId
    let counterpartyDesc = "" //transaction.counterpartyDisplayDescription(deviceCountryCode: deviceCountryCode) ?? ""
    let sentToMyselfText = "Sent to myself"

    self.isIncoming = transaction.isIncoming
    let possibleTwitterContact = transaction.twitterContact ?? transaction.invitation?.counterpartyTwitterContact
    if let data = possibleTwitterContact?.profileImageData {
      self.counterpartyAvatar = UIImage(data: data)
    }

    if isIncoming {
      counterpartyDescription = counterpartyDesc
      if transaction.invitation != nil {
        receiverAddress = counterpartyAddress
      } else {
        receiverAddress = transaction.vouts
          .sorted { $0.index < $1.index }
          .compactMap { $0.address }
          .filter { $0.isReceiveAddress }
          .first?
          .addressId
      }
    } else {
      if let tempTx = transaction.temporarySentTransaction {
        if tempTx.isSentToSelf {
          counterpartyDescription = sentToMyselfText
        } else {
          counterpartyDescription = counterpartyDesc
        }
        receiverAddress = transaction.counterpartyAddress?.addressId ?? ""
      } else {
        if transaction.isSentToSelf {
          counterpartyDescription = sentToMyselfText
          receiverAddress = transaction.vouts.first?.addressIDs.first
        } else {
          counterpartyDescription = counterpartyDesc
          receiverAddress = counterpartyAddress
        }
      }
    }

    self.confirmations = transaction.confirmations
    self.isConfirmed = transaction.isConfirmed
    self.invitationStatus = transaction.invitation?.status

    let receivedAmt = transaction.receivedAmount
    let inputSatoshis = transaction.invitation?.btcAmount ?? receivedAmt // invitation amount supercedes transaction amount
    let fromAmount = NSDecimalNumber(integerAmount: inputSatoshis, currency: .BTC)
    let currencyPair = CurrencyPair(primary: .BTC, fiat: .USD)
    self.sentAmountAtCurrentConverter = CurrencyConverter(rates: rates,
                                                          fromAmount: fromAmount,
                                                          currencyPair: currencyPair)
    if transaction.netWalletAmount != 0 { //leave btcReceived as nil if zero
      self.btcReceived = NSDecimalNumber(integerAmount: abs(receivedAmt), currency: .BTC)
    }

    self.netWalletAmount = NSDecimalNumber(integerAmount: transaction.netWalletAmount, currency: .BTC)
    self.primaryCurrency = primaryCurrency
    self.date = transaction.date ?? transaction.invitation?.sentDate
    self.memo = transaction.memo ?? ""
  }

  var isTemporaryTransaction: Bool {
    guard let tx = transaction else { return false }
    return tx.temporarySentTransaction != nil
  }

  var isTwitterContact: Bool {
    guard let tx = transaction else { return false }
    if tx.twitterContact != nil {
      return true
    } else if let invitation = tx.invitation, invitation.counterpartyTwitterContact != nil {
      return true
    }
    return false
  }

  /// overridden by detail cell model
  var invitationStatusDescription: String? {
    guard let status = invitationStatus else { return nil }

    switch status {
    case .notSent:      return "\(CKStrings.dropBitWithTrademark) Not Yet Sent"
    case .requestSent:  return "\(CKStrings.dropBitWithTrademark) Sent"
    case .addressSent:  return "Address Sent"
    case .completed:    return nil
    case .canceled:     return "\(CKStrings.dropBitWithTrademark) Canceled"
    case .expired:      return "\(CKStrings.dropBitWithTrademark) Expired"
    }
  }

  var transactionIsInvalidated: Bool {
    if let status = invitationStatus, [.canceled, .expired].contains(status) {
      return true
    } else {
      return broadcastFailed
    }
  }

  func currentRate(for currency: CurrencyCode) -> Double? {
    return sentAmountAtCurrentConverter.rates[currency]
  }

  var fromCurrency: CurrencyCode {
    return sentAmountAtCurrentConverter.fromCurrency
  }

  var toCurrency: CurrencyCode {
    return sentAmountAtCurrentConverter.toCurrency
  }

  /// `rate` and `currency` parameters refer to non-BTC and `amount` parameter refers to the BTC amount
  func newConverter(withRate rate: Double, currency: CurrencyCode, btcAmount: NSDecimalNumber) -> CurrencyConverter {
    return CurrencyConverter(fromBtcTo: currency, fromAmount: btcAmount, rates: [.BTC: 1, currency: rate])
  }

  var receivedAmountAtCurrentConverter: CurrencyConverter? {
    guard let amount = netWalletAmount, let rate = currentRate(for: .USD) else { return nil }
    return newConverter(withRate: rate, currency: .USD, btcAmount: amount)
  }

}

/*
protocol CounterpartyRepresentable: AnyObject {

  var isIncoming: Bool { get }
  var counterpartyName: String? { get }
  var counterpartyAddressId: String? { get }

  func counterpartyDisplayIdentity(deviceCountryCode: Int?) -> String?

}

extension CounterpartyRepresentable {

  func counterpartyDisplayDescription(deviceCountryCode: Int?) -> String? {
    if let name = counterpartyName {
      return name
    } else if let identity = counterpartyDisplayIdentity(deviceCountryCode: deviceCountryCode) {
      return identity
    } else {
      return counterpartyAddressId
    }
  }

}

extension CKMTransaction: CounterpartyRepresentable {

  var counterpartyName: String? {
    if let twitterCounterparty = invitation?.counterpartyTwitterContact {
      return twitterCounterparty.formattedScreenName
    } else if let inviteName = invitation?.counterpartyName {
      return inviteName
    } else {
      let relevantNumber = phoneNumber ?? invitation?.counterpartyPhoneNumber
      return relevantNumber?.counterparty?.name
    }
  }

  func counterpartyDisplayIdentity(deviceCountryCode: Int?) -> String? {
    if let counterpartyTwitterContact = self.twitterContact {
      return counterpartyTwitterContact.formattedScreenName  // should include @-sign
    }

    if let relevantPhoneNumber = invitation?.counterpartyPhoneNumber ?? phoneNumber {
      let globalPhoneNumber = relevantPhoneNumber.asGlobalPhoneNumber

      var format: PhoneNumberFormat = .international
      if let code = deviceCountryCode {
        format = (code == globalPhoneNumber.countryCode) ? .national : .international
      }
      let formatter = CKPhoneNumberFormatter(format: format)

      return try? formatter.string(from: globalPhoneNumber)
    }

    return nil
  }

  var counterpartyAddressId: String? {
    return counterpartyReceiverAddressId
  }
}
*/
*/
