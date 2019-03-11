//
//  CKPredicate.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

struct CKPredicate {

  struct Invitation {

    static func withId(_ id: String) -> NSPredicate {
      let path = #keyPath(CKMInvitation.id)
      return NSPredicate(format: "\(path) == %@", id)
    }

    static func idIsIn(_ ids: [String]) -> NSPredicate {
      let path = #keyPath(CKMInvitation.id)
      return NSPredicate(format: "\(path) IN %@", ids)
    }

    static func withTxid(_ txid: String) -> NSPredicate {
      let path = #keyPath(CKMInvitation.txid)
      return NSPredicate(format: "\(path) == %@", txid)
    }

    static func hasTxid() -> NSPredicate {
      let path = #keyPath(CKMInvitation.txid)
      let notNil = NSPredicate(format: "\(path) != nil")
      let notEmpty = NSPredicate(format: "\(path) != %@", "")
      return NSCompoundPredicate(type: .and, subpredicates: [notNil, notEmpty])
    }

    static func withoutTxid() -> NSPredicate {
      let path = #keyPath(CKMInvitation.txid)
      let isNil = NSPredicate(format: "\(path) == nil")
      let isEmpty = NSPredicate(format: "\(path) == %@", "")
      return NSCompoundPredicate(type: .or, subpredicates: [isNil, isEmpty])
    }

    static func invitationHasUnacknowledgedPrefix() -> NSPredicate {
      let idPath = #keyPath(CKMInvitation.id)
      return NSPredicate(format: "\(idPath) BEGINSWITH %@", CKMInvitation.unacknowledgementPrefix)
    }

    static func withStatuses(_ statuses: [InvitationStatus]) -> NSPredicate {
      let statusValues = statuses.map { $0.rawValue }
      let path = #keyPath(CKMInvitation.status)
      return NSPredicate(format: "\(path) IN %@", statusValues)
    }

    static func hasProvidedAddress() -> NSPredicate {
      let path = #keyPath(CKMInvitation.addressProvidedToSender)
      return NSPredicate(format: "\(path) != nil")
    }

    static func transactionTxidDoesNotMatch() -> NSPredicate {
      let transactionTxidPath = #keyPath(CKMInvitation.transaction.txid)
      let invitationTxidPath = #keyPath(CKMInvitation.txid)
      return NSPredicate(format: "\(transactionTxidPath) != \(invitationTxidPath)")
    }

    /// Useful for identifying invitations that have provided an address, but not yet received a transaction.
    static func updatedFulfilledReceivedAddressRequests() -> NSPredicate {
      let predicates = [withStatuses([.addressSent]),
                        withoutTxid(),
                        hasProvidedAddress()]
      return NSCompoundPredicate(type: .and, subpredicates: predicates)
    }

  }

  struct TemporarySentTransaction {

    static func invitationExists() -> NSPredicate {
      let invitationPath = #keyPath(CKMTemporarySentTransaction.transaction.invitation)
      return NSPredicate(format: "\(invitationPath) != nil")
    }

    static func inactiveInvitationStatus() -> NSPredicate {
      let canceled = InvitationStatus.canceled.rawValue
      let expired = InvitationStatus.expired.rawValue
      let statusPath = #keyPath(CKMTemporarySentTransaction.transaction.invitation.status)
      return NSPredicate(format: "\(statusPath) == %d OR \(statusPath) == %d", canceled, expired)
    }

    static func withInactiveInvitation() -> NSPredicate {
      return NSCompoundPredicate(type: .and, subpredicates: [invitationExists(), inactiveInvitationStatus()])
    }

    static func broadcastFailed(is value: Bool) -> NSPredicate {
      let path = #keyPath(CKMTemporarySentTransaction.transaction.broadcastFailed)
      return NSPredicate(format: "\(path) == %@", NSNumber(value: value))
    }

  }

  struct DerivativePath {

    private static let purposeKeyPath = #keyPath(CKMDerivativePath.purpose)
    private static let coinKeyPath = #keyPath(CKMDerivativePath.coin)
    private static let accountKeyPath = #keyPath(CKMDerivativePath.account)
    private static let changeKeyPath = #keyPath(CKMDerivativePath.change)
    private static let indexKeyPath = #keyPath(CKMDerivativePath.index)
    private static let serverAddressPath = #keyPath(CKMDerivativePath.serverAddress)

    static func withoutServerAddress() -> NSPredicate {
      return NSPredicate(format: "\(serverAddressPath) == nil")
    }

    static func forChangeIndex(_ changeIndex: Int) -> NSPredicate {
      let purposePredicate = NSPredicate(format: "\(purposeKeyPath) = %d", 49)
      let coinPredicate = NSPredicate(format: "\(coinKeyPath) = %d", 0)
      let accountPredicate = NSPredicate(format: "\(accountKeyPath) = %d", 0)
      let changePredicate = NSPredicate(format: "\(changeKeyPath) = %d", changeIndex)
      return NSCompoundPredicate(andPredicateWithSubpredicates: [
        purposePredicate, coinPredicate, accountPredicate, changePredicate
        ])
    }
  }

  struct Transaction {

    static func withoutDayAveragePrice() -> NSPredicate {
      let pricePath = #keyPath(CKMTransaction.dayAveragePrice)
      return NSPredicate(format: "\(pricePath) == nil")
    }

    static func withValidTxid() -> NSPredicate {
      let withoutInvitationPrefixPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: txidHasInvitationPrefix())
      let withoutFailedPrefixPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: txidHasFailedPrefix())
      let notEmptyPredicate = txidNotEmpty()
      return NSCompoundPredicate(type: .and, subpredicates: [withoutInvitationPrefixPredicate,
                                                             withoutFailedPrefixPredicate,
                                                             notEmptyPredicate])
    }

    static func txidNotEmpty() -> NSPredicate {
      let txidPath = #keyPath(CKMTransaction.txid)
      return NSPredicate(format: "\(txidPath) != %@", "")
    }

    static func txidHasInvitationPrefix() -> NSPredicate {
      let txidPath = #keyPath(CKMTransaction.txid)
      return NSPredicate(format: "\(txidPath) BEGINSWITH %@", CKMTransaction.invitationTxidPrefix)
    }

    static func txidHasFailedPrefix() -> NSPredicate {
      let txidPath = #keyPath(CKMTransaction.txid)
      return NSPredicate(format: "\(txidPath) BEGINSWITH %@", CKMTransaction.failedTxidPrefix)
    }

    static func txidIn(_ txids: [String]) -> NSPredicate {
      let txidKeyPath = #keyPath(CKMTransaction.txid)
      return NSPredicate(format: "\(txidKeyPath) IN %@", txids)
    }

    static func txidNotIn(_ txids: [String]) -> NSPredicate {
      let txidKeyPath = #keyPath(CKMTransaction.txid)
      return NSPredicate(format: "NOT \(txidKeyPath) IN %@", txids)
    }

    static func invitationTxidNotIn(_ txids: [String]) -> NSPredicate {
      let txidKeyPath = #keyPath(CKMTransaction.invitation.txid)
      return NSPredicate(format: "NOT \(txidKeyPath) IN %@", txids)
    }

    static func invitationHasTxid() -> NSPredicate {
      let path = #keyPath(CKMTransaction.invitation.txid)
      let notNilPredicate = NSPredicate(format: "\(path) != nil")
      let notEmptyPredicate = NSPredicate(format: "\(path) != %@", "")
      return NSCompoundPredicate(type: .and, subpredicates: [notNilPredicate, notEmptyPredicate])
    }

    static func invitationCompletedBefore(_ minDate: Date) -> NSPredicate {
      let path = #keyPath(CKMTransaction.invitation.completedAt)
      let notNilPredicate = NSPredicate(format: "\(path) != nil")
      let beforeDatePredicate = NSPredicate(format: "\(path) < %@", minDate as NSDate)
      return NSCompoundPredicate(type: .and, subpredicates: [notNilPredicate, beforeDatePredicate])
    }

    static func withoutInvitation() -> NSPredicate {
      let invitationKeyPath = #keyPath(CKMTransaction.invitation)
      return NSPredicate(format: "\(invitationKeyPath) == nil")
    }

    static func withInvitation() -> NSPredicate {
      let invitationKeyPath = #keyPath(CKMTransaction.invitation)
      return NSPredicate(format: "\(invitationKeyPath) != nil")
    }

    static func withoutTemporaryTransaction() -> NSPredicate {
      let tempTxKeyPath = #keyPath(CKMTransaction.temporarySentTransaction)
      return NSPredicate(format: "\(tempTxKeyPath) == nil")
    }

    static func broadcastedBefore(_ minDate: Date) -> NSPredicate {
      let broadcastedAtPath = #keyPath(CKMTransaction.broadcastedAt)
      return NSPredicate(format: "\(broadcastedAtPath) < %@", minDate as NSDate)
    }

    static func broadcastFailed(is value: Bool) -> NSPredicate {
      let path = #keyPath(CKMTransaction.broadcastFailed)
      return NSPredicate(format: "\(path) == %@", NSNumber(value: value))
    }

  }

  struct Vin {
    static func withoutBelongsToWallet() -> NSPredicate {
      let path = #keyPath(CKMVin.belongsToWallet)
      return NSPredicate(format: "\(path) == nil")
    }

    static func matching(response: TransactionVinResponse) -> NSPredicate {
      return matching(previousTxid: response.txid, previousVoutIndex: response.vout)
    }

    static func matching(previousTxid: String, previousVoutIndex: Int) -> NSPredicate {
      let txidPath = #keyPath(CKMVin.previousTxid)
      let voutIndexPath = #keyPath(CKMVin.previousVoutIndex)
      let txidPredicate = NSPredicate(format: "\(txidPath) == %@", previousTxid)
      let indexPredicate = NSPredicate(format: "\(voutIndexPath) == %d", previousVoutIndex)
      return NSCompoundPredicate(type: .and, subpredicates: [txidPredicate, indexPredicate])
    }

  }

  struct Vout {

    static func isOurs() -> NSPredicate {
      let path = #keyPath(CKMVout.address)
      return NSPredicate(format: "%K != nil", path)
    }

    static func belongsToChangeAddress() -> NSPredicate {
      let path = #keyPath(CKMVout.address.derivativePath.change)
      return NSPredicate(format: "\(path) == %d", CKMDerivativePath.changeIsChangeValue)
    }

    static func hasSufficientConfirmations(min: Int) -> NSPredicate {
      let path = #keyPath(CKMVout.transaction.confirmations)
      return NSPredicate(format: "\(path) >= %d", min)
    }

    static func isSpent(value: Bool) -> NSPredicate {
      let path = #keyPath(CKMVout.isSpent)
      return NSPredicate(format: "\(path) == %@", NSNumber(value: value))
    }

    static func isSpendable(minReceiveConfirmations: Int = 1) -> NSPredicate {
      let isChangePredicate = belongsToChangeAddress()
      let receiveConfirmationsPredicate = hasSufficientConfirmations(min: minReceiveConfirmations)
      let sufficientConfirmationsPredicate = NSCompoundPredicate(type: .or, subpredicates: [isChangePredicate,
                                                                                            receiveConfirmationsPredicate])

      let isOursPredicate = isOurs()
      let notSpentPredicate = isSpent(value: false)

      return NSCompoundPredicate(type: .and, subpredicates: [isOursPredicate,
                                                             notSpentPredicate,
                                                             sufficientConfirmationsPredicate])
    }

    static func matching(response: TransactionVoutResponse) throws -> NSPredicate {
      let txidKeyPath = #keyPath(CKMVout.txid)
      guard let txid = response.txid else { throw CKPersistenceError.missingValue(key: txidKeyPath) }
      return matching(txid: txid, index: response.n)
    }

    /// Find a matching CKMVout instance with txid and `n` index.
    ///
    /// - Parameters:
    ///   - txid: The txid that funded the vout.
    ///   - index: The `n` index of the vout. Vouts are unordered in the transaction, so `n` preserves order.
    /// - Returns: An NSPredicate to use for querying for a Vout that matches txid and `n` index.
    static func matching(txid: String, index: Int) -> NSPredicate {
      let txidKeyPath = #keyPath(CKMVout.txid)
      let indexKeyPath = #keyPath(CKMVout.index)
      let txidPredicate = NSPredicate(format: "\(txidKeyPath) == %@", txid)
      let voutPredicate = NSPredicate(format: "\(indexKeyPath) == %d", index)
      return NSCompoundPredicate(type: .and, subpredicates: [txidPredicate, voutPredicate])
    }
  }

}
