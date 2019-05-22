//
//  CKMTransaction+FetchRequests.swift
//  DropBit
//
//  Created by Ben Winters on 3/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

typealias IncomingOutgoingTuple = (incoming: Bool, outgoing: Bool)

extension CKMTransaction {

  static func findAll(in context: NSManagedObjectContext) -> [CKMTransaction] {
    return transactions(in: context)
  }

  static func findAll(byTxids txids: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let path = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(path) IN %@", txids)

    return transactions(matching: predicate, in: context)
  }

  static func findAllFailed(in context: NSManagedObjectContext) -> [CKMTransaction] {
    let predicate = CKPredicate.Transaction.broadcastFailed(is: true)
    return transactions(matching: predicate, in: context)
  }

  static func findAllGroomable(in context: NSManagedObjectContext) -> [CKMTransaction] {
    let invitationKeyPath = #keyPath(CKMTransaction.invitation)
    let tempTxKeyPath = #keyPath(CKMTransaction.temporarySentTransaction)
    let invitationPredicate = NSPredicate(format: "\(invitationKeyPath) == nil")
    let tempTxPredicate = NSPredicate(format: "\(tempTxKeyPath) == nil")
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [invitationPredicate, tempTxPredicate])
    return transactions(matching: predicate, in: context)
  }

  /**
   Returns transactions with a valid txid stored locally, that are at least 5 minutes old,
   but do not appear in txids received from API.
   */
  static func findAllToFail(notIn txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {

    // broadcastedAt or completedAt is older than 5 minutes
    let minimumValidDate = Date().addingTimeInterval(-180)

    let transactionSubpredicates = [CKPredicate.Transaction.broadcastedBefore(minimumValidDate),
                                    CKPredicate.Transaction.txidNotIn(txidsToKeep),
                                    CKPredicate.Transaction.withValidTxid()] // doesn't have invitation prefix

    let failedTransactionPredicate = NSCompoundPredicate(type: .and, subpredicates: transactionSubpredicates)

    let invitationSubpredicates = [CKPredicate.Transaction.invitationCompletedBefore(minimumValidDate),
                                   CKPredicate.Transaction.invitationHasTxid(),
                                   CKPredicate.Transaction.invitationTxidNotIn(txidsToKeep)]

    let failedInvitationPredicate = NSCompoundPredicate(type: .and, subpredicates: invitationSubpredicates)

    let combinedFailedPredicate = NSCompoundPredicate(type: .or, subpredicates: [failedTransactionPredicate,
                                                                                 failedInvitationPredicate])

    // ignore those already marked as failed
    let notYetFailedPredicate = CKPredicate.Transaction.broadcastFailed(is: false)

    let fullPredicate = NSCompoundPredicate(type: .and, subpredicates: [combinedFailedPredicate,
                                                                        notYetFailedPredicate])

    return transactions(matching: fullPredicate, in: context)
  }

  /**
   Returns an array of transactions which were previously marked as broadcastFailed, but are now observed
   to be included in txids seen by the server.
   */
  static func findAllToUnfail(in txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let failedPredicate = CKPredicate.Transaction.broadcastFailed(is: true)
    let txidPredicate = CKPredicate.Transaction.txidIn(txidsToKeep)
    let fullPredicate = NSCompoundPredicate(type: .and, subpredicates: [failedPredicate,
                                                                        txidPredicate])
    return transactions(matching: fullPredicate, in: context)
  }

  static func findAllToDelete(notIn txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let unseenTxidPredicate = CKPredicate.Transaction.txidNotIn(txidsToKeep)
    let noTempTxPredicate = CKPredicate.Transaction.withoutTemporaryTransaction()
    let noInvitationPredicate = CKPredicate.Transaction.withoutInvitation()
    let predicate = NSCompoundPredicate(type: .and, subpredicates: [unseenTxidPredicate, noTempTxPredicate, noInvitationPredicate])
    return transactions(matching: predicate, in: context)
  }

  static func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    let withInvitationPredicate = CKPredicate.Transaction.withInvitation()
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = withInvitationPredicate

    let dropbitInvitation = transactions(with: fetchRequest, in: context).asSet()
    let incoming = dropbitInvitation.filter { $0.isIncoming }
    let outgoing = dropbitInvitation.subtracting(incoming)

    return (incoming: incoming.isNotEmpty, outgoing: outgoing.isNotEmpty)
  }

  static func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    let withInvitationPredicate = CKPredicate.Transaction.withoutInvitation()
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = withInvitationPredicate

    let regularTransactions = transactions(with: fetchRequest, in: context).asSet()
    let incoming = regularTransactions.filter { $0.isIncoming }
    let outgoing = regularTransactions.subtracting(incoming)

    return (incoming: incoming.isNotEmpty, outgoing: outgoing.isNotEmpty)
  }

  static func findAllTxidsFullyConfirmed(in context: NSManagedObjectContext) -> [String] {
    let confirmationKeyPath = #keyPath(CKMTransaction.confirmations)
    let txidKeyPath = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(confirmationKeyPath) > %d", fullyConfirmedThreshold)
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    fetchRequest.propertiesToFetch = [txidKeyPath]
    return transactions(with: fetchRequest, in: context).map { $0.txid }
  }

  private static func transactions(matching predicate: NSPredicate, in context: NSManagedObjectContext) -> [CKMTransaction] {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    return transactions(with: fetchRequest, in: context)
  }

  private static func transactions(
    with fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest(),
    in context: NSManagedObjectContext) -> [CKMTransaction] {
    var result: [CKMTransaction] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }

  static func find(byTxid txid: String, in context: NSManagedObjectContext) -> CKMTransaction? {
    let path = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(path) = %@", txid)
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    fetchRequest.fetchLimit = 1

    var ckmTransaction: CKMTransaction?
    context.performAndWait {
      do {
        ckmTransaction = try context.fetch(fetchRequest).first
      } catch {
        ckmTransaction = nil
      }
    }
    return ckmTransaction
  }

  static func findOrCreate(
    with txResponse: TransactionResponse,
    in context: NSManagedObjectContext,
    relativeToBlockHeight blockHeight: Int,
    fullSync: Bool
    ) -> CKMTransaction {
    var transaction: CKMTransaction!
    context.performAndWait {
      if let foundTx = CKMTransaction.find(byTxid: txResponse.txid, in: context) {
        transaction = foundTx
      } else {
        transaction = CKMTransaction(insertInto: context)
      }
    }
    transaction.configure(with: txResponse, in: context, relativeToBlockHeight: blockHeight, fullSync: fullSync)
    return transaction
  }

  static func findOrCreate(with data: OutgoingTransactionData, in context: NSManagedObjectContext) -> CKMTransaction {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.fetchLimit = 1
    let keyPath = #keyPath(CKMTransaction.txid)
    let invitationTxid = CKMTransaction.invitationTxidPrefix + data.txid
    let txidPredicate = NSPredicate(format: "\(keyPath) = %@", data.txid)
    let invitationPredicate = NSPredicate(format: "\(keyPath) = %@", invitationTxid)
    let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [txidPredicate, invitationPredicate])
    fetchRequest.predicate = predicate

    let transaction: CKMTransaction
    do {
      if let foundTx = try context.fetch(fetchRequest).first {
        transaction = foundTx
      } else {
        transaction = CKMTransaction(insertInto: context)
      }
    } catch {
      transaction = CKMTransaction(insertInto: context)
    }

    transaction.configure(with: data, in: context)
    return transaction
  }

}
