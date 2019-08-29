//
//  TransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
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

  init(managedTx: CKMTransaction,
       selectedCurrency: SelectedCurrency,
       lightningLoadAddress: String?) {
    self.walletTxType = .onChain
    self.selectedCurrency = selectedCurrency
    self.direction = managedTx.isIncoming ? .in : .out


    self.memo = managedTx.memo
  }

}

extension CKMTransaction {

  /// txid does not begin with a prefix (e.g. invitations with placeholder Transaction objects)
  var txidIsActualTxid: Bool {
    let isInviteOrFailed = txid.starts(with: CKMTransaction.invitationTxidPrefix) || txid.starts(with: CKMTransaction.failedTxidPrefix)
    return !isInviteOrFailed
  }

  var isCancellable: Bool {
    guard let invite = invitation else { return false }
    let cancellableStatuses: [InvitationStatus] = [.notSent, .requestSent, .addressSent]
    return (!isIncoming && cancellableStatuses.contains(invite.status))
  }

  /// Returns first outgoing vout address, otherwise tx must be sent to self
  var counterpartyReceiverAddressId: String? {
    if isIncoming {
      return invitation?.addressProvidedToSender
    } else {

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
  }

  /// Returns nil if any of our addresses are in vout addresses
  private func firstVoutAddress(from voutAddressIDs: Set<String>, notMatchingAddresses ourAddresses: Set<String>) -> String? {
    return ourAddresses.isDisjoint(with: voutAddressIDs) ? voutAddressIDs.first : nil
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

//extension CKMTransaction: CounterpartyRepresentable {
//
//  var counterpartyName: String? {
//    if let twitterCounterparty = invitation?.counterpartyTwitterContact {
//      return twitterCounterparty.formattedScreenName
//    } else if let inviteName = invitation?.counterpartyName {
//      return inviteName
//    } else {
//      let relevantNumber = phoneNumber ?? invitation?.counterpartyPhoneNumber
//      return relevantNumber?.counterparty?.name
//    }
//  }
//
//  func counterpartyConfig(deviceCountryCode: Int) -> TransactionCellCounterpartyConfig? {
//    if let counterpartyTwitterContact = self.twitterContact {
//      return counterpartyTwitterContact.formattedScreenName  // should include @-sign
//    }
//
//    if let relevantPhoneNumber = invitation?.counterpartyPhoneNumber ?? phoneNumber {
//      let globalPhoneNumber = relevantPhoneNumber.asGlobalPhoneNumber
//
//      var format: PhoneNumberFormat = .international
//      if let code = deviceCountryCode {
//        format = (code == globalPhoneNumber.countryCode) ? .national : .international
//      }
//      let formatter = CKPhoneNumberFormatter(format: format)
//
//      return try? formatter.string(from: globalPhoneNumber)
//    }
//
//    return nil
//  }
//
//  var counterpartyAddressId: String? {
//    return counterpartyReceiverAddressId
//  }
//}
