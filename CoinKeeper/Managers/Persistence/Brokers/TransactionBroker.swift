//
//  TransactionBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit
import CNBitcoinKit

class TransactionBroker: CKPersistenceBroker, TransactionBrokerType {

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void> {
    guard transactionResponses.isNotEmpty else { return Promise.value(()) }
    return databaseManager.persistTransactions(from: transactionResponses, in: context, relativeToCurrentHeight: blockHeight, fullSync: fullSync)
  }

  @discardableResult
  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
    ) -> CKMTransaction {
    return databaseManager.persistTemporaryTransaction(
      from: transactionData,
      with: outgoingTransactionData,
      txid: txid,
      invitation: invitation,
      in: context
    )
  }

  @discardableResult
  func persistTemporaryTransaction(from lightningResponse: LNTransactionResponse,
                                   in context: NSManagedObjectContext) -> CKMTransaction {
    return databaseManager.persistTemporaryTransaction(from: lightningResponse, in: context)
  }

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return databaseManager.containsRegularTransaction(in: context)
  }

  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return databaseManager.containsDropbitTransaction(in: context)
  }

  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) {
    return databaseManager.deleteTransactions(notIn: txids, in: context)
  }

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
    return databaseManager.transactionsWithoutDayAveragePrice(in: context)
  }

}
