//
//  MockTransactionBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockTransactionBroker: CKPersistenceBroker, TransactionBrokerType {

  func persistTemporaryTransaction(from response: LNTransactionResponse,
                                   in context: NSManagedObjectContext) -> CKMTransaction {
    return CKMTransaction(insertInto: context)
  }

  func persistTransactions(from transactionResponses: [TransactionResponse],
                           in context: NSManagedObjectContext,
                           relativeToCurrentHeight blockHeight: Int,
                           fullSync: Bool) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistTemporaryTransaction(from transactionData: CNBTransactionData,
                                   with outgoingTransactionData: OutgoingTransactionData,
                                   txid: String,
                                   invitation: CKMInvitation?,
                                   in context: NSManagedObjectContext) -> CKMTransaction {
    return CKMTransaction(insertInto: context)
  }

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) { }

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
    return Promise.value([])
  }

}
