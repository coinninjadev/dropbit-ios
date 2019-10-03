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

  func amountDetails(with currentRates: ExchangeRates, fiatCurrency: CurrencyCode) -> TransactionAmountDetails {
    let amount = NSDecimalNumber(integerAmount: self.netWalletAmount, currency: .BTC)
    return TransactionAmountDetails(btcAmount: amount, fiatCurrency: fiatCurrency, exchangeRates: currentRates)
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
