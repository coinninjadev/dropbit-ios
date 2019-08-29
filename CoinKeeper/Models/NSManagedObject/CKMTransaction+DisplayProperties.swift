//
//  CKMTransaction+DisplayProperties.swift
//  DropBit
//
//  Created by Ben Winters on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

//TODO: Move this logic into cell view model
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
