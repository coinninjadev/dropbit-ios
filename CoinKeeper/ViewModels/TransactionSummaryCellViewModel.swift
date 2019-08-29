//
//  TransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit
import UIKit

struct TransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {
  var walletTxType: WalletTransactionType
  var selectedCurrency: SelectedCurrency
  var direction: TransactionDirection
  var isLightningTransfer: Bool
  var status: TransactionStatus
  var amountDetails: TransactionAmountDetails
  var memo: String?
  var counterpartyConfig: TransactionCellCounterpartyConfig?
  var receiverAddress: String?
  var lightningInvoice: String?

  /// Initialize with protocol so that the initialization is simple and the logic for transforming stored properties
  /// is contained in isolated functions or computed properties inside the protocol implementation.
  init(object: TransactionSummaryCellViewModelObject,
       selectedCurrency: SelectedCurrency,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       deviceCountryCode: Int) {
    self.walletTxType = object.walletTxType
    self.selectedCurrency = selectedCurrency
    self.direction = object.direction
    self.isLightningTransfer = object.isLightningTransfer
    self.status = object.status
    self.amountDetails = object.amountDetails(with: exchangeRates, fiatCurrency: fiatCurrency)
    self.memo = object.memo
    self.counterpartyConfig = object.counterpartyConfig(for: deviceCountryCode)
    self.receiverAddress = object.receiverAddress
    self.lightningInvoice = object.lightningInvoice
  }

}

protocol TransactionSummaryCellViewModelObject {
  var walletTxType: WalletTransactionType { get }
  var direction: TransactionDirection { get }
  var isLightningTransfer: Bool { get }
  var status: TransactionStatus { get }
  var memo: String? { get }
  var receiverAddress: String? { get }
  var lightningInvoice: String? { get }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails
  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig?

}

extension CKMTransaction: TransactionSummaryCellViewModelObject {

  var walletTxType: WalletTransactionType {
    return .onChain
  }

  var direction: TransactionDirection {
    return self.isIncoming ? .in : .out
  }

  var status: TransactionStatus {
    if broadcastFailed { return .failed }
    return statusForInvitation ?? statusForTransaction
  }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    let amount = NSDecimalNumber(integerAmount: self.netWalletAmount, currency: .BTC)
    return TransactionAmountDetails(btcAmount: amount, fiatCurrency: fiatCurrency, exchangeRates: currentRates)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    let maybeTwitter = self.invitation?.counterpartyTwitterContact.flatMap { TransactionCellTwitterConfig(contact: $0) }
    let maybeName = counterpartyName(with: maybeTwitter)
    let maybeNumber = displayPhoneNumber(for: deviceCountryCode)
    return TransactionCellCounterpartyConfig(failableWithName: maybeName,
                                             displayPhoneNumber: maybeNumber,
                                             twitterConfig: maybeTwitter)
  }

  var receiverAddress: String? {
    switch direction {
    case .in:
      if let invite = invitation {
        return invite.addressProvidedToSender
      } else {
        return vouts
          .sorted { $0.index < $1.index }
          .compactMap { $0.address }
          .filter { $0.isReceiveAddress }
          .first?.addressId
      }
    case .out:
      if isTemporaryTransaction {
        return counterpartyReceiverAddressId
      } else if isSentToSelf {
        return vouts.first?.addressIDs.first
      } else {
        return counterpartyReceiverAddressId
      }
    }
  }

  private func counterpartyName(with twitterConfig: TransactionCellTwitterConfig?) -> String? {
    if let config = twitterConfig {
      return config.displayName
    } else if let inviteName = invitation?.counterpartyName {
      return inviteName
    } else {
      let relevantNumber = phoneNumber ?? invitation?.counterpartyPhoneNumber
      return relevantNumber?.counterparty?.name
    }
  }

  private func displayPhoneNumber(for deviceCountryCode: Int) -> String? {
    guard let relevantPhoneNumber = invitation?.counterpartyPhoneNumber ?? phoneNumber else { return nil }
    let globalPhoneNumber = relevantPhoneNumber.asGlobalPhoneNumber
    let format: PhoneNumberFormat = (deviceCountryCode == globalPhoneNumber.countryCode) ? .national : .international
    let formatter = CKPhoneNumberFormatter(format: format)
    return try? formatter.string(from: globalPhoneNumber)
  }

  /// Returns first outgoing vout address, otherwise tx must be sent to self
  private var counterpartyReceiverAddressId: String? {
    if let addressId = counterpartyAddress?.addressId {
      return addressId
    } else {

      // ourAddresses are addresses we own by relationship to AddressTransactionSummary objects
      guard let context = self.managedObjectContext else { return nil }
      let ourAddressStrings = addressTransactionSummaries.map { $0.addressId }
      let ourAddresses = CKMAddress.find(withAddresses: ourAddressStrings, in: context)
      let ourAddressIds = ourAddresses.map { $0.addressId }.asSet()

      // firstOutgoing is first vout addressID where ourAddresses doesn't appear in vout's addressIDs
      let firstOutgoing = vouts.compactMap { self.firstVoutAddress(from: Set($0.addressIDs), notMatchingAddresses: ourAddressIds) }.first
      return firstOutgoing
    }
  }

  /// Returns nil if any of our addresses are in vout addresses
  private func firstVoutAddress(from voutAddressIDs: Set<String>, notMatchingAddresses ourAddresses: Set<String>) -> String? {
    return ourAddresses.isDisjoint(with: voutAddressIDs) ? voutAddressIDs.first : nil
  }

  var lightningInvoice: String? {
    return nil
  }

  private var isTemporaryTransaction: Bool {
    return temporarySentTransaction != nil
  }

  private var statusForInvitation: TransactionStatus? {
    guard let invitation = self.invitation else { return nil }
    switch invitation.status {
    case .notSent,
         .requestSent,
         .addressSent:  return .pending
    case .canceled:     return .canceled
    case .expired:      return .expired
    case .completed:    return .completed
    }
  }

  private var statusForTransaction: TransactionStatus {
    if isTemporaryTransaction {
      return .broadcasting
    } else {
      switch confirmations {
      case 0:   return .pending
      default:  return .completed
      }
    }
  }

}

// MARK: - Computed Amounts
extension CKMTransaction {

  /// networkFee is calculated in Satoshis, should be sum(vin) - sum(vout), but only vin/vout pertaining to our addresses
  var networkFee: Int {
    if let tempTransaction = temporarySentTransaction {
      return tempTransaction.feeAmount
    } else if let invitation = invitation {
      switch invitation.status {
      case .requestSent: return invitation.fees
      default: break
      }
    }
    return sumVins - sumVouts
  }

  /// Net effect of the transaction on the wallet of current user, returned in Satoshis
  var netWalletAmount: Int {
    if let tx = temporarySentTransaction {
      return (tx.amount + tx.feeAmount) * -1 // negative, to show an outgoing amount with a negative impact on wallet balance
    }

    if vins.isEmpty && vouts.isEmpty, let invite = invitation { // Incoming invitation without valid transaction
      return invite.btcAmount
    }

    return myVouts - myVins
  }

  /// The amount received after the network fee has been subtracted from the sent amount
  var receivedAmount: Int {
    return isIncoming ? netWalletAmount : (abs(netWalletAmount) - networkFee)
  }

  /// Returns sum of `amount` value from all vins
  private var sumVins: Int {
    return NSArray(array: vins.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sum of `amount` value from all vouts
  private var sumVouts: Int {
    return NSArray(array: vouts.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sent amount from vins, relative to addresses owned by user's wallet
  private var myVins: Int {
    let vinsToUse = vins.filter { $0.belongsToWallet }
    return NSArray(array: vinsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns received amount from vouts, relative to addresses owned by user's wallet
  private var myVouts: Int {
    let voutsToUse = vouts.filter { $0.address != nil }
    return NSArray(array: voutsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

}
