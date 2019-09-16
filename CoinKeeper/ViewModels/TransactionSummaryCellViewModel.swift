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
  var isLightningUpgrade: Bool
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
    self.isLightningUpgrade = object.isLightningUpgrade
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
  var isLightningUpgrade: Bool { get }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails
  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig?

}

extension TransactionSummaryCellViewModelObject {

  func priorityCounterpartyName(with twitterConfig: TransactionCellTwitterConfig?,
                                invitation: CKMInvitation?,
                                phoneNumber: CKMPhoneNumber?) -> String? {
    if let config = twitterConfig {
      return config.displayName
    } else if let inviteName = invitation?.counterpartyName {
      return inviteName
    } else {
      let relevantNumber = phoneNumber ?? invitation?.counterpartyPhoneNumber
      return relevantNumber?.counterparty?.name
    }
  }

  func priorityPhoneNumber(for deviceCountryCode: Int, invitation: CKMInvitation?, phoneNumber: CKMPhoneNumber?) -> String? {
    guard let relevantPhoneNumber = invitation?.counterpartyPhoneNumber ?? phoneNumber else { return nil }
    let globalPhoneNumber = relevantPhoneNumber.asGlobalPhoneNumber
    let format: PhoneNumberFormat = (deviceCountryCode == globalPhoneNumber.countryCode) ? .national : .international
    let formatter = CKPhoneNumberFormatter(format: format)
    return try? formatter.string(from: globalPhoneNumber)
  }

  func counterpartyConfig(for walletEntry: CKMWalletEntry, deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    let maybeTwitter = walletEntry.twitterContact.flatMap { TransactionCellTwitterConfig(contact: $0) }
    let maybeName = priorityCounterpartyName(with: maybeTwitter, invitation: nil, phoneNumber: walletEntry.phoneNumber)
    let maybeNumber = priorityPhoneNumber(for: deviceCountryCode, invitation: nil, phoneNumber: walletEntry.phoneNumber)
    return TransactionCellCounterpartyConfig(failableWithName: maybeName,
                                             displayPhoneNumber: maybeNumber,
                                             twitterConfig: maybeTwitter)
  }

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
    return invitation?.transactionStatus ?? statusForTransaction
  }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    let amount = NSDecimalNumber(integerAmount: self.netWalletAmount, currency: .BTC)
    return TransactionAmountDetails(btcAmount: amount, fiatCurrency: fiatCurrency, exchangeRates: currentRates)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    let maybeTwitter = self.invitation?.counterpartyTwitterContact.flatMap { TransactionCellTwitterConfig(contact: $0) }
    let maybeName = priorityCounterpartyName(with: maybeTwitter, invitation: invitation, phoneNumber: phoneNumber)
    let maybeNumber = priorityPhoneNumber(for: deviceCountryCode, invitation: invitation, phoneNumber: phoneNumber)
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

typealias Satoshis = Int

// MARK: - Computed Amounts
extension CKMTransaction {

  /// should be sum(vin) - sum(vout), but only vin/vout pertaining to our addresses
  var networkFee: Satoshis {
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

  /// Net effect of the transaction on the wallet of current user
  var netWalletAmount: Satoshis {
    if let tx = temporarySentTransaction {
      return (tx.amount + tx.feeAmount) * -1 // negative, to show an outgoing amount with a negative impact on wallet balance
    }

    if vins.isEmpty && vouts.isEmpty, let invite = invitation { // Incoming invitation without valid transaction
      return invite.btcAmount
    }

    return myVouts - myVins
  }

  /// The amount received after the network fee has been subtracted from the sent amount
  var receivedAmount: Satoshis {
    return isIncoming ? netWalletAmount : (abs(netWalletAmount) - networkFee)
  }

  /// Returns sum of `amount` value from all vins
  private var sumVins: Satoshis {
    return NSArray(array: vins.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sum of `amount` value from all vouts
  private var sumVouts: Satoshis {
    return NSArray(array: vouts.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sent amount from vins, relative to addresses owned by user's wallet
  private var myVins: Satoshis {
    let vinsToUse = vins.filter { $0.belongsToWallet }
    return NSArray(array: vinsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns received amount from vouts, relative to addresses owned by user's wallet
  private var myVouts: Satoshis {
    let voutsToUse = vouts.filter { $0.address != nil }
    return NSArray(array: voutsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

}

struct LightningTransactionViewModelObject: TransactionSummaryCellViewModelObject {
  let entry: CKMLNLedgerEntry

  init?(walletEntry: CKMWalletEntry) {
    guard let ledgerEntry = walletEntry.ledgerEntry else { return nil }
    self.entry = ledgerEntry
  }

  var walletTxType: WalletTransactionType {
    return .lightning
  }

  var direction: TransactionDirection {
    return TransactionDirection(lnDirection: entry.direction)
  }

  var isLightningTransfer: Bool {
    return entry.type == .btc
  }

  var status: TransactionStatus {
    if let invitation = entry.walletEntry?.invitation {
      return invitation.transactionStatus
    } else {
      return entry.transactionStatus
    }
  }

  var memo: String? {
    return entry.memo
  }

  var receiverAddress: String? {
    return nil
  }

  var lightningInvoice: String? {
    return entry.request
  }

  var isLightningUpgrade: Bool {
    return false
  }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    let amount = NSDecimalNumber(integerAmount: entry.value, currency: .BTC)
    return TransactionAmountDetails(btcAmount: amount, fiatCurrency: fiatCurrency, exchangeRates: currentRates)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    guard let walletEntry = entry.walletEntry else { return nil }
    return counterpartyConfig(for: walletEntry, deviceCountryCode: deviceCountryCode)
  }

}

struct LightningInvitationViewModelObject: TransactionSummaryCellViewModelObject {

  let walletEntry: CKMWalletEntry
  let invitation: CKMInvitation

  init?(invitation: CKMInvitation) {
    guard let walletEntry = invitation.walletEntry else { return nil }
    self.walletEntry = walletEntry
    self.invitation = invitation
  }

  var walletTxType: WalletTransactionType {
    return invitation.walletTxTypeCase
  }

  var direction: TransactionDirection {
    switch invitation.side {
    case .sender:   return .out
    case .receiver: return .in
    }
  }

  var isLightningTransfer: Bool {
    return false
  }

  var isLightningUpgrade: Bool {
    return false
  }

  var status: TransactionStatus {
    return invitation.transactionStatus
  }

  var memo: String? {
    return walletEntry.memo
  }

  var receiverAddress: String? {
    return nil
  }

  var lightningInvoice: String? {
    return nil
  }

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    let btcAmount = NSDecimalNumber(integerAmount: invitation.btcAmount, currency: .BTC)
    let fiatAmount = NSDecimalNumber(integerAmount: invitation.fiatAmount, currency: .USD)
    return TransactionAmountDetails(btcAmount: btcAmount, fiatCurrency: fiatCurrency, exchangeRates: currentRates,
                                    fiatWhenCreated: fiatAmount, fiatWhenTransacted: nil)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    return counterpartyConfig(for: walletEntry, deviceCountryCode: deviceCountryCode)
  }

}

///Only necessary because of the optional relationship between CKMWalletEntry and CKMLNLedgerEntry
struct FallbackViewModelObject: TransactionSummaryCellViewModelObject {

  let walletTxType: WalletTransactionType

  init(walletTxType: WalletTransactionType) {
    self.walletTxType = walletTxType
  }

  let direction: TransactionDirection = .in
  let isLightningTransfer: Bool = false
  let isLightningUpgrade: Bool = false
  let status: TransactionStatus = .failed
  var memo: String?
  var receiverAddress: String?
  var lightningInvoice: String?

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    return TransactionAmountDetails(btcAmount: .zero, fiatCurrency: fiatCurrency, exchangeRates: currentRates)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    return nil
  }

}
