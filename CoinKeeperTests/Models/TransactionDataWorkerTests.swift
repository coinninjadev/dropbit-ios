//
//  TransactionDataWorkerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
import PromiseKit
@testable import DropBit

class TransactionDataWorkerTests: XCTestCase {

  var sut: TransactionDataWorker!
  var mockPersistenceManager: MockPersistenceManager!
  var mockNetworkManager: MockNetworkManager!
  var mockWalletManager: MockWalletManager!
  var mockAnalyticsManager: MockAnalyticsManager!

  override func setUp() {
    super.setUp()

    mockPersistenceManager = MockPersistenceManager()
    mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager, analyticsManager: MockAnalyticsManager())
    mockWalletManager = MockWalletManager(words: [])
    mockAnalyticsManager = MockAnalyticsManager()

    sut = TransactionDataWorker(
      walletManager: mockWalletManager,
      persistenceManager: mockPersistenceManager,
      networkManager: mockNetworkManager,
      analyticsManager: mockAnalyticsManager
    )
  }

  override func tearDown() {
    sut = nil
    mockWalletManager = nil
    mockNetworkManager = nil
    mockPersistenceManager = nil
    super.tearDown()
  }

  func testPerformingTxFetchAsksNetworkManagerATSResponses() {
    let stack = InMemoryCoreDataStack()
    _ = sut.performFetchAndStoreAllOnChainTransactions(in: stack.context)

    XCTAssertTrue(mockNetworkManager.wasAskedToFetchTransactionSummariesForAddresses, "should ask network manager for ats data")
  }

  func testGroomingTransactionsMarksFailedTransactions() {
    let stack = InMemoryCoreDataStack()

    let expectation = XCTestExpectation(description: "1 transaction should be confirmed as failed")

    let failedTxid = "f232aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    let goodTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    let goodBroadcastedAt = Date()
    let failedBroadcastedAt = Date().addingTimeInterval(-301) //Created 5m 1s ago

    stack.context.performAndWait {
      let failedTx = CKMTransaction(insertInto: stack.context)
      let failedResponse = TransactionResponse(txid: failedTxid)
      failedTx.configure(with: failedResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)
      failedTx.broadcastedAt = failedBroadcastedAt

      let failedTempTx = CKMTemporarySentTransaction(insertInto: stack.context)
      failedTempTx.createdAt = failedBroadcastedAt
      failedTx.temporarySentTransaction = failedTempTx

      let goodTx = CKMTransaction(insertInto: stack.context)
      let goodResponse = TransactionResponse(txid: goodTxid)
      goodTx.configure(with: goodResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)
      goodTx.broadcastedAt = goodBroadcastedAt

      // Set dictionary of expected responses to be returned by mockNetworkManager.getBCITransactionDetails(for txid: String)
      self.mockNetworkManager.confirmFailedTransactionValueByTxid = [
        failedTxid: true,
        goodTxid: false
      ]

      _ = self.sut.groomFailedTransactions(notIn: [goodTxid], in: stack.context)
        .done { _ in

          XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 object should be deleted after grooming")
          XCTAssertEqual(stack.context.insertedObjects.count, 3, "3 objects should eventually be inserted")

          let failedTxs = CKMTransaction.findAllFailed(in: stack.context)
          XCTAssertEqual(failedTxs.count, 1, "1 transaction should be marked as failed after grooming")

          expectation.fulfill()
      }

      wait(for: [expectation], timeout: 10.0)
    }
  }

  func testGroomingTransactionsMarksFailedReceivedInvitations() {
    let stack = InMemoryCoreDataStack()

    let expectation = XCTestExpectation(description: "1 received invitation should be confirmed as failed after grooming")

    let goodTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    let failedTxid1 = "f232aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    let pendingTxid = "f233aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    let failedCompletedAt = Date().addingTimeInterval(-181) //Created 3m 1s ago
    let pendingCompletedAt = Date().addingTimeInterval(-179) //Created 2m 59s ago

    stack.context.performAndWait {

      let goodTx = CKMTransaction(insertInto: stack.context)
      let goodResponse = TransactionResponse(txid: goodTxid)
      goodTx.configure(with: goodResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)

      // Failed 1
      let failedTx1 = CKMTransaction(insertInto: stack.context)
      let failedResponse1 = TransactionResponse(txid: CKMTransaction.invitationTxidPrefix + failedTxid1)
      failedTx1.configure(with: failedResponse1, in: stack.context, relativeToBlockHeight: 0, fullSync: false)

      let failedInvitation1 = CKMInvitation(insertInto: stack.context)
      failedInvitation1.setTxid(to: failedTxid1)
      failedInvitation1.completedAt = failedCompletedAt
      failedTx1.invitation = failedInvitation1

      // Not eligible for failure
      let pendingTx = CKMTransaction(insertInto: stack.context)
      let pendingResponse = TransactionResponse(txid: CKMTransaction.invitationTxidPrefix + pendingTxid)
      pendingTx.configure(with: pendingResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)

      let pendingInvitation = CKMInvitation(insertInto: stack.context)
      pendingInvitation.setTxid(to: pendingTxid)
      pendingInvitation.completedAt = pendingCompletedAt
      pendingTx.invitation = pendingInvitation

      self.mockNetworkManager.confirmFailedTransactionValueByTxid = [
        goodTxid: false,
        failedTxid1: true,
        pendingTxid: true
      ]

      _ = self.sut.groomFailedTransactions(notIn: [goodTxid], in: stack.context)
        .done { _ in
          XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 object should be deleted after grooming")
          XCTAssertEqual(stack.context.insertedObjects.count, 5, "5 objects should eventually be inserted")

          let failedTxs = CKMTransaction.findAllFailed(in: stack.context)
          XCTAssertEqual(failedTxs.count, 1, "1 transaction should be marked as failed after grooming")

          expectation.fulfill()
        }
        .catch(policy: .allErrors) { log.error($0, message: nil) }

      wait(for: [expectation], timeout: 10.0)
    }
  }

  /*
   func testGroomingTransactionsMarksUnfailedTransactions() {
   let stack = InMemoryCoreDataStack()

   let failedTxid = "f232aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
   let goodTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
   let failedCreatedAt = Date().addingTimeInterval(-301) //Created 5m 1s ago

   stack.context.performAndWait {
   let failedTx = CKMTransaction(insertInto: stack.context)
   let failedResponse = TransactionResponse(txid: failedTxid)
   failedTx.configure(with: failedResponse, in: stack.context, relativeToBlockHeight: 0)

   let failedTempTx = CKMTemporarySentTransaction(insertInto: stack.context)
   failedTempTx.createdAt = failedCreatedAt
   failedTx.temporarySentTransaction = failedTempTx

   let goodTx = CKMTransaction(insertInto: stack.context)
   let goodResponse = TransactionResponse(txid: goodTxid)
   goodTx.configure(with: goodResponse, in: stack.context, relativeToBlockHeight: 0)

   _ = self.sut.groomFailedTransactions(notIn: [goodTxid], in: stack.context)

   XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 object should be deleted after grooming")
   XCTAssertEqual(stack.context.insertedObjects.count, 3, "3 objects should eventually be inserted")

   let failedTxs = CKMTransaction.findAllFailed(in: stack.context)
   XCTAssertEqual(failedTxs.count, 1, "1 transaction should be marked as failed after grooming")

   do {
   try stack.context.save()
   } catch {
   XCTFail("failed to save context: \(error)")
   }

   // Groom with a new array of txids where the previously missing txid is now present
   let newTxids = [goodTxid, failedTxid]
   _ = self.sut.groomFailedTransactions(notIn: newTxids, in: stack.context)

   let failedTransactions = CKMTransaction.findAllFailed(in: stack.context)
   XCTAssertEqual(failedTransactions.count, 0, "0 transactions should be marked as failed after grooming with new txids")
   XCTAssertEqual(stack.context.updatedObjects.count, 1, "1 object should eventually be updated")
   }
   }
   */

}
