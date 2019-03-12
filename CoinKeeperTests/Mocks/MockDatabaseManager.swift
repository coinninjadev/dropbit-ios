//
//  MockDatabaseManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 7/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import CoreData
import PromiseKit
import CNBitcoinKit

class MockDatabaseManager: PersistenceDatabaseType {

  func unverifyUser(in context: NSManagedObjectContext) {}
  func removeWalletId(in context: NSManagedObjectContext) {}
  let stack = InMemoryCoreDataStack()

  func walletId(in context: NSManagedObjectContext) -> String? {
    return nil
  }

  func userId(in context: NSManagedObjectContext) -> String? {
    return nil
  }

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
    return Promise { _ in }
  }

  var groomAddressTransactionSummariesFromResponsesWasCalled = false
  func groomAddressTransactionSummaries(from responses: [AddressTransactionSummaryResponse], in context: NSManagedObjectContext) -> Promise<Void> {
    groomAddressTransactionSummariesFromResponsesWasCalled = true
    return Promise { _ in }
  }

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  lazy var mainQueueContext: NSManagedObjectContext = {
    return stack.context
  }()

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
    return nil
  }

  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return []
  }

  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return []
  }

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistTransactionSummaries(from responses: [AddressTransactionSummaryResponse], in context: NSManagedObjectContext) -> Promise<Set<Int>> {
    return Promise { _ in }
  }

  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext) {}

  func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1],
                                     hasher: HashingManager,
                                     in context: NSManagedObjectContext) {
  }

  var deleteTransactionsFromResponsesWasCalled = false
  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) {
    deleteTransactionsFromResponsesWasCalled = true
  }

  func groomTransactions(from txids: [String], in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func createBackgroundContext() -> NSManagedObjectContext {
    return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
  }

  func persistWalletId(_ id: String, in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistUserId(_ id: String, in context: NSManagedObjectContext) -> Promise<CKMUser> {
    return Promise { _ in }
  }

  func persistVerificationStatus(_ status: String, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return Promise { _ in }
  }

  func persistServerAddress(for metaAddress: CNBMetaAddress,
                            createdAt: Date,
                            wallet: CKMWallet,
                            in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func walletAndUserId(in context: NSManagedObjectContext) -> Promise<(walletId: String, userId: String)> {
    return Promise { _ in }
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return []
  }

  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return []
  }

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return UserVerificationStatus.pending
  }

  func updateLastReceiveAddressIndex(index: Int, in context: NSManagedObjectContext) { }

  func updateLastChangeAddressIndex(index: Int, in context: NSManagedObjectContext) { }

  func deleteAll(in context: NSManagedObjectContext) { }

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return 0
  }

  func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
    return 0
  }

  func matchContactsIfPossible(with contactCacheManager: ContactCacheManagerType) {
  }
}
