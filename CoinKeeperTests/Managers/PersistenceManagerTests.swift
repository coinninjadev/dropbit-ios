//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import Strongbox

class PersistenceManagerTests: XCTestCase {
  var sut: PersistenceManager!
  var mockKeychainAccessor: MockKeychainAccessorType!

  override func setUp() {
    super.setUp()
    self.sut = PersistenceManager()
    self.mockKeychainAccessor = MockKeychainAccessorType()
  }

  override func tearDown() {
    self.sut.userDefaultsManager.deleteAll()
    self.sut = nil
    self.mockKeychainAccessor = nil
    super.tearDown()
  }

  // MARK: keychain
  private func setupKeychainTests() {
    let keychainManager = PersistenceManager.Keychain(store: mockKeychainAccessor)
    self.sut = PersistenceManager(keychainManager: keychainManager)
    _ = self.sut.keychainManager.store(valueToHash: "foo", key: .userPin)
  }

  func testStoringValueInKeychainTellsAccessorToStore() {
    setupKeychainTests()
    XCTAssertTrue(mockKeychainAccessor.wasAskedToArchive, "keychain accessor should store value")
  }

  func testRetrievingValueTellsAccessorToRetrieve() {
    setupKeychainTests()

    let actualValue = self.sut.keychainManager.retrieveValue(for: .userPin) as? String ?? ""

    XCTAssertTrue(mockKeychainAccessor.wasAskedToUnarchive, "keychain accessor should return value")
    XCTAssertEqual(actualValue, "foo".sha256(), "value should equal expected value")
  }

  func testClearingValueRemovesFromStorage() {
    setupKeychainTests()

    _ = self.sut.keychainManager.store(anyValue: nil, key: .userPin)

    let newValue = self.sut.keychainManager.retrieveValue(for: .userPin)
    XCTAssertNil(newValue, "keychain value should be nil after removal")
  }

  // MARK: database
  func testGroomingTransactionsDelegatesToDatabaseManager() {
    let mockDatabaseManager = MockDatabaseManager()
    self.sut = PersistenceManager(databaseManager: mockDatabaseManager)

    _ = self.sut.deleteTransactions(notIn: [], in: InMemoryCoreDataStack().context)

    XCTAssertTrue(mockDatabaseManager.deleteTransactionsFromResponsesWasCalled, "should tell databaseManager to handle grooming")
  }

  func testGroomingTransactionsRemovesTransactionsNotBelongingToWallet() {
    let stack = InMemoryCoreDataStack()
    stack.context.performAndWait {
      let goodTx = CKMTransaction(insertInto: stack.context)
      let goodTxid = "abc123"
      let goodResponse = TransactionResponse(txid: goodTxid)
      goodTx.configure(with: goodResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)
      let badTx = CKMTransaction(insertInto: stack.context)
      let badTxid = "bad_id"
      let badResopnse = TransactionResponse(txid: badTxid)
      badTx.configure(with: badResopnse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)

      XCTAssertEqual(stack.context.insertedObjects.count, 2, "2 objects should initially be inserted")
      XCTAssertEqual(stack.context.registeredObjects.count, 2, "2 objects should initially be registered")
      XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 objects should initially be deleted")

      _ = self.sut.deleteTransactions(notIn: [goodTxid], in: stack.context)

      XCTAssertEqual(stack.context.deletedObjects.count, 1, "1 object should be deleted after grooming")

      try? stack.context.save()

      let objectTxid = stack.context.registeredObjects.first.flatMap { $0 as? CKMTransaction }?.txid ?? badTxid
      XCTAssertEqual(objectTxid, goodTxid, "remaining object's txid should equal good txid")
    }
  }

  func testGroomingTransactionsDoesNotRemoveAnyTransactionsIfAllAreGood() {
    let stack = InMemoryCoreDataStack()
    stack.context.performAndWait {
      let goodTx = CKMTransaction(insertInto: stack.context)
      let goodTxid = "abc123"
      let goodResponse = TransactionResponse(txid: goodTxid)
      goodTx.configure(with: goodResponse, in: stack.context, relativeToBlockHeight: 0, fullSync: false)
      let goodTx2 = CKMTransaction(insertInto: stack.context)
      let goodTxid2 = "123abc"
      let goodResponse2 = TransactionResponse(txid: goodTxid2)
      goodTx2.configure(with: goodResponse2, in: stack.context, relativeToBlockHeight: 0, fullSync: false)

      XCTAssertEqual(stack.context.insertedObjects.count, 2, "2 objects should initially be inserted")
      XCTAssertEqual(stack.context.registeredObjects.count, 2, "2 objects should initially be registered")
      XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 objects should initially be deleted")

      _ = self.sut.deleteTransactions(notIn: [goodTxid, goodTxid2], in: stack.context)

      XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 object should be deleted after grooming")

      do {
        try stack.context.save()
      } catch {
        XCTFail("failed to save context: \(error)")
      }

      XCTAssertEqual(stack.context.registeredObjects.count, 2, "remaining objects should still equal 2")
      XCTAssertEqual(stack.context.deletedObjects.count, 0, "0 objects should still be deleted")
      XCTAssertEqual(stack.context.insertedObjects.count, 0, "0 objects should eventually be inserted")
    }
  }

  // MARK: user defaults
  func testPendingInvitationsWithIDReturnsProperInvitationData() {
    let pendingInv1 = PendingInvitationData(
      id: "1",
      btcAmount: 1,
      fiatAmount: 1,
      feeAmount: 1,
      name: "one",
      phoneNumber: GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212"),
      address: nil,
      addressPubKey: nil,
      userNotified: false,
      failedToSendAt: nil,
      memo: "test memo"
    )
    let pendingInv2 = PendingInvitationData(
      id: "2",
      btcAmount: 2,
      fiatAmount: 1,
      feeAmount: 2,
      name: nil,
      phoneNumber: nil,
      address: nil,
      addressPubKey: nil,
      userNotified: false,
      failedToSendAt: nil,
      memo: "test memo"
    )

    let userDefaultsManager = PersistenceManager.CKUserDefaults()
    self.sut = PersistenceManager(userDefaultsManager: userDefaultsManager)

    self.sut.persist(pendingInvitationData: pendingInv1)
    self.sut.persist(pendingInvitationData: pendingInv2)

    let actualInvite = self.sut.pendingInvitation(with: "1")

    XCTAssertEqual(actualInvite?.id ?? "0", "1")
    XCTAssertEqual(actualInvite?.btcAmount ?? 0, 1)
    XCTAssertEqual(actualInvite?.feeAmount ?? 0, 1)
    XCTAssertEqual(actualInvite?.name ?? "", "one")
    XCTAssertEqual(actualInvite?.phoneNumber?.nationalNumber ?? "", "3305551212")
    XCTAssertEqual(actualInvite?.memo ?? "", "test memo")

    userDefaultsManager.removePendingInvitation(with: "1")
    userDefaultsManager.removePendingInvitation(with: "2")
    XCTAssertEqual(userDefaultsManager.pendingInvitations().count, 0, "removal should remove all pending from user defaults")
  }

  func testReceiveAddressIndexGaps() {
    XCTAssertTrue(sut.userDefaultsManager.receiveAddressIndexGaps.isEmpty, "receiveAddressIndexGaps should be empty at start of test")

    let expectedGaps = Set([1, 3, 5, 28])
    sut.userDefaultsManager.receiveAddressIndexGaps = expectedGaps

    XCTAssertEqual(sut.userDefaultsManager.receiveAddressIndexGaps, expectedGaps, "receiveAddressIndexGaps should equal the gaps that were set")
  }

}
