//
//  TransactionViewModelObject+CKMTransaction.swift
//  DropBit
//
//  Created by Ben Winters on 10/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

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

  func amountFactory(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountsFactoryType {
    return TransactionAmountsFactory(transaction: self, fiatCurrency: fiatCurrency, currentRates: currentRates)
  }

  func counterpartyConfig(for deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
    let relevantTwitterContact = self.invitation?.counterpartyTwitterContact ?? self.twitterContact
    let maybeTwitter = relevantTwitterContact.flatMap { TransactionCellTwitterConfig(contact: $0) }
    let maybeName = priorityCounterpartyName(with: maybeTwitter, invitation: invitation, phoneNumber: phoneNumber)
    let maybeNumber = priorityPhoneNumber(for: deviceCountryCode, invitation: invitation, phoneNumber: phoneNumber)
    return TransactionCellCounterpartyConfig(failableWithName: maybeName,
                                             displayPhoneNumber: maybeNumber,
                                             twitterConfig: maybeTwitter)
  }

  var isPendingTransferToLightning: Bool {
    return false
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
  var counterpartyReceiverAddressId: String? {
    if isIncoming {
      return invitation?.addressProvidedToSender
    }

    if let addressId = counterpartyAddress?.addressId {
      return addressId
    }

    // ourAddresses are addresses we own by relationship to AddressTransactionSummary objects
    guard let context = self.managedObjectContext else { return nil }
    let ourAddressStrings = addressTransactionSummaries.map { $0.addressId }
    let ourAddresses = CKMAddress.find(withAddresses: ourAddressStrings, in: context)
    let ourAddressIds = ourAddresses.map { $0.addressId }.asSet()

    // firstOutgoing is first vout addressID where ourAddresses doesn't appear in vout's addressIDs
    let firstOutgoing = vouts.compactMap { self.firstVoutAddress(from: Set($0.addressIDs), notMatchingAddresses: ourAddressIds) }.first

    return firstOutgoing
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

  var paymentIdIsValid: Bool {
    return txidIsActualTxid
  }

  var invitationStatus: InvitationStatus? {
    return invitation?.status
  }

}

extension CKMTransaction: TransactionDetailCellActionable {

  var bitcoinAddress: String? {
    return receiverAddress
  }

  func removeFromTransactionHistory() {
    // CKMTransactions cannot be hidden
  }

}
