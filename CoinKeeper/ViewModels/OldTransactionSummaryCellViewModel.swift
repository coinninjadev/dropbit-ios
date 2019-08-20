//
//  TransactionSummaryCellViewModel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import CNBitcoinKit

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

  /// Empty initializer
  init() {
    self.counterpartyDescription = ""
    self.confirmations = 0
    self.isConfirmed = false
    self.isIncoming = false
    self.broadcastFailed = false
    let rates: ExchangeRates = [.USD: 7000, .BTC: 1]
    let currencyPair = CurrencyPair(primary: .USD, secondary: .BTC, fiat: .USD)
    self.sentAmountAtCurrentConverter = CurrencyConverter(rates: rates, fromAmount: .zero, currencyPair: currencyPair)
    self.primaryCurrency = .USD
    self.memo = ""
  }

  init(
    walletEntry: CKMWalletEntry,
    rates: ExchangeRates,
    primaryCurrency: CurrencyCode,
    deviceCountryCode: Int?
    ) {

    //TODO
    self.counterpartyDescription = ""
    self.confirmations = 0
    self.isConfirmed = false
    self.isIncoming = false
    self.broadcastFailed = false
    let rates: ExchangeRates = [.USD: 7000, .BTC: 1]
    let currencyPair = CurrencyPair(primary: .USD, secondary: .BTC, fiat: .USD)
    self.sentAmountAtCurrentConverter = CurrencyConverter(rates: rates, fromAmount: .zero, currencyPair: currencyPair)
    self.primaryCurrency = .USD
    self.memo = ""
  }

  init(
    transaction: CKMTransaction,
    rates: ExchangeRates,
    primaryCurrency: CurrencyCode,
    deviceCountryCode: Int?
    ) {
    self.transaction = transaction
    self.broadcastFailed = transaction.broadcastFailed
    let counterpartyAddress = transaction.counterpartyAddressId
    let counterpartyDesc = transaction.counterpartyDisplayDescription(deviceCountryCode: deviceCountryCode) ?? ""
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

  var transactionStatusDescription: String {
    guard !isTemporaryTransaction else { return "Broadcasting" }
    let count = confirmations
    switch count {
    case 0:    return "Pending"
    default:  return "Complete"
    }
  }

  var statusDescription: String {
    if broadcastFailed {
      return "Failed to Broadcast"
    } else {
      return invitationStatusDescription ?? transactionStatusDescription
    }
  }

  var hidden: Bool {
    let count = confirmations
    return count >= 1

  }

  var descriptionColor: UIColor {
    guard !transactionIsInvalidated else { return .darkPeach }
    if isConfirmed {
      return .darkGrayText
    } else {
      return .warning
    }
  }

  var transactionIsInvalidated: Bool {
    if let status = invitationStatus, [.canceled, .expired].contains(status) {
      return true
    } else {
      return broadcastFailed
    }
  }

  var dateDescriptionFull: String {
    guard let date = date else { return "" }
    return CKDateFormatter.displayFull.string(from: date)
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

  func amountLabels(for converter: CurrencyConverter) -> (primary: String, secondary: String) {
    let secondaryCurrency: CurrencyCode = (primaryCurrency == .BTC) ? .USD : .BTC
    let amounts = amountStrings(for: converter, primary: primaryCurrency, secondary: secondaryCurrency)
    let secondaryAmountString = amounts.secondary ?? "–"

    if let primaryAmountString = amounts.primary {
      return (primaryAmountString, secondaryAmountString)
    } else {
      return ("–", secondaryAmountString)
    }
  }

  private func amountStrings(for converter: CurrencyConverter,
                             primary: CurrencyCode,
                             secondary: CurrencyCode) -> (primary: String?, secondary: String?) {
    let absPrimary = converter.amount(forCurrency: primary)?.absoluteValue()
    let absSecondary = converter.amount(forCurrency: secondary)?.absoluteValue()

    let pString = absPrimary.flatMap { converter.amountStringWithSymbol($0, primary) }
    let sString = absSecondary.flatMap { converter.amountStringWithSymbol($0, secondary) }

    return (pString, sString)
  }

}
