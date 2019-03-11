//
//  DatabaseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class DatabaseTests: XCTestCase {

  var sut: PersistenceManager.Database!

  override func setUp() {
    super.setUp()
    let config = CoreDataStackConfig(stackType: .main, storeType: .inMemory)
    sut = PersistenceManager.Database(stackConfig: config)
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testGroomingTransactionsRemovesTransactionsNotBelongingToWallet() {
    let context = sut.viewContext
    let goodTx = CKMTransaction(insertInto: context)
    let goodTxid = "abc123"
    let goodResponse = TransactionResponse(txid: goodTxid)
    goodTx.configure(with: goodResponse, in: context, relativeToBlockHeight: 0, fullSync: false)
    let badTx = CKMTransaction(insertInto: context)
    let badTxid = "bad_id"
    let badResopnse = TransactionResponse(txid: badTxid)
    badTx.configure(with: badResopnse, in: context, relativeToBlockHeight: 0, fullSync: false)

    XCTAssertEqual(context.insertedObjects.count, 2, "2 objects should initially be inserted")
    XCTAssertEqual(context.registeredObjects.count, 2, "2 objects should initially be registered")
    XCTAssertEqual(context.deletedObjects.count, 0, "0 objects should initially be deleted")

    _ = self.sut.deleteTransactions(notIn: [goodTxid], in: context)

    XCTAssertEqual(context.deletedObjects.count, 1, "1 object should be deleted after grooming")
  }

  func testGroomingTransactionsDoesNotRemoveAnyTransactionsIfAllAreGood() {
    let context = sut.viewContext
    let goodTx = CKMTransaction(insertInto: context)
    let goodTxid = "abc123"
    let goodResponse = TransactionResponse(txid: goodTxid)
    goodTx.configure(with: goodResponse, in: context, relativeToBlockHeight: 0, fullSync: false)
    let goodTx2 = CKMTransaction(insertInto: context)
    let goodTxid2 = "123abc"
    let goodResponse2 = TransactionResponse(txid: goodTxid2)
    goodTx2.configure(with: goodResponse2, in: context, relativeToBlockHeight: 0, fullSync: false)

    XCTAssertEqual(context.insertedObjects.count, 2, "2 objects should initially be inserted")
    XCTAssertEqual(context.registeredObjects.count, 2, "2 objects should initially be registered")
    XCTAssertEqual(context.deletedObjects.count, 0, "0 objects should initially be deleted")

    _ = self.sut.deleteTransactions(notIn: [goodTxid, goodTxid2], in: context)

    XCTAssertEqual(context.deletedObjects.count, 0, "0 object should be deleted after grooming")

    do {
      try context.save()
    } catch {
      XCTFail("failed to save context: \(error)")
    }

    XCTAssertEqual(context.registeredObjects.count, 2, "remaining objects should still equal 2")
    XCTAssertEqual(context.deletedObjects.count, 0, "0 objects should still be deleted")
    XCTAssertEqual(context.insertedObjects.count, 0, "0 objects should eventually be inserted")
  }

}
