//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
import PromiseKit
@testable import DropBit
import Strongbox

class PersistenceManagerTests: MockedPersistenceTestCase {
  var sut: PersistenceManager!
  var mockKeychainAccessor: MockKeychainAccessorType!
  var mockKeychainManager: CKKeychain!
  var mockContactCacheManager: MockContactCacheManager!

  override func setUp() {
    super.setUp()
    mockContactCacheManager = MockContactCacheManager()
    mockKeychainAccessor = MockKeychainAccessorType()
    mockUserDefaultsManager = MockUserDefaultsManager()
    mockKeychainManager = CKKeychain(store: mockKeychainAccessor)

    self.sut = PersistenceManager(
      keychainManager: mockKeychainManager,
      databaseManager: mockDatabaseManager,
      userDefaultsManager: mockUserDefaultsManager,
      contactCacheManager: mockContactCacheManager,
      brokers: mockBrokers
    )
  }

  override func tearDown() {
    sut.userDefaultsManager.deleteAll()
    mockKeychainAccessor = nil
    mockKeychainManager = nil
    mockDatabaseManager = nil
    mockContactCacheManager = nil
    mockUserDefaultsManager = nil
    sut = nil
    super.tearDown()
  }

  // MARK: keychain
  private func setupKeychainTests() -> Promise<Void> {
    let keychainManager = CKKeychain(store: mockKeychainAccessor)
    self.sut = PersistenceManager(keychainManager: keychainManager)
    return self.sut.keychainManager.store(valueToHash: "foo", key: .userPin)
  }

  func testStoringValueInKeychainTellsAccessorToStore() {
    let expectation = XCTestExpectation(description: "setupKeychain")
    setupKeychainTests()
      .done {
        XCTAssertTrue(self.mockKeychainAccessor.wasAskedToArchive, "keychain accessor should store value")
        expectation.fulfill()
      }.cauterize()
    wait(for: [expectation], timeout: 3.0)
  }

  func testRetrievingValueTellsAccessorToRetrieve() {
    let expectation = XCTestExpectation(description: "setupKeychain")
    setupKeychainTests()
      .done {
        let actualValue = self.sut.keychainManager.retrieveValue(for: .userPin) as? String ?? ""

        XCTAssertTrue(self.mockKeychainAccessor.wasAskedToUnarchive, "keychain accessor should return value")
        XCTAssertEqual(actualValue, "foo".sha256(), "value should equal expected value")
        expectation.fulfill()
      }.cauterize()
    wait(for: [expectation], timeout: 3.0)
  }

  func testClearingValueRemovesFromStorage() {
    let expectation = XCTestExpectation(description: "setupKeychain")
    setupKeychainTests()
      .then { self.sut.keychainManager.store(anyValue: nil, key: .userPin) }
      .done {
        let newValue = self.sut.keychainManager.retrieveValue(for: .userPin)
        XCTAssertNil(newValue, "keychain value should be nil after removal")
        expectation.fulfill()
      }.cauterize()
    wait(for: [expectation], timeout: 3.0)
  }

  // MARK: database
  func testGroomingTransactionsDelegatesToDatabaseManager() {
    let mockDatabaseManager = MockPersistenceDatabaseManager()
    self.sut = PersistenceManager(databaseManager: mockDatabaseManager)

    _ = self.sut.brokers.transaction.deleteTransactions(notIn: [], in: InMemoryCoreDataStack().context)

    XCTAssertTrue(mockDatabaseManager.deleteTransactionsFromResponsesWasCalled, "should tell databaseManager to handle grooming")
  }

  // MARK: user defaults
  func testReceiveAddressIndexGaps() {
    XCTAssertTrue(sut.brokers.wallet.receiveAddressIndexGaps.isEmpty, "receiveAddressIndexGaps should be empty at start of test")

    let expectedGaps = Set([1, 3, 5, 28])
    sut.brokers.wallet.receiveAddressIndexGaps = expectedGaps

    XCTAssertEqual(sut.brokers.wallet.receiveAddressIndexGaps, expectedGaps, "receiveAddressIndexGaps should equal the gaps that were set")
  }

  // MARK: contact matching
  func testContactMatching() {
    // given
    let contactCacheConfig = CoreDataStackConfig(stackType: .contactCache, storeType: .inMemory)
    let mockContactCacheMgr = ContactCacheManager(stackConfig: contactCacheConfig)
    let dbStackConfig = CoreDataStackConfig(stackType: .main, storeType: .inMemory)
    let mockDBMgr = CKDatabase(stackConfig: dbStackConfig)
    sut = PersistenceManager(
      keychainManager: mockKeychainManager,
      databaseManager: mockDBMgr,
      userDefaultsManager: self.mockUserDefaultsManager,
      contactCacheManager: mockContactCacheMgr
    )

    let context = sut.viewContext

    // set up ckm data
    let global1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let global2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305557777")
    let ckmPhone1 = CKMPhoneNumber(phoneNumber: global1, insertInto: context)
    let ckmPhone2 = CKMPhoneNumber(phoneNumber: global2, insertInto: context)
    let counterparty1 = CKMCounterparty(name: "Rick", insertInto: context)
    ckmPhone1?.counterparty = counterparty1
    _ = ckmPhone1.map { counterparty1.phoneNumbers.insert($0) }

    // set up ccm data
    let ccmContext = mockContactCacheMgr.viewContext
    let ccmPhone1 = CCMPhoneNumber(insertInto: ccmContext)
    let ccmPhone2 = CCMPhoneNumber(insertInto: ccmContext)
    let ccmMetadata1 = CCMValidatedMetadata(phoneNumber: global1, hashedGlobalNumber: "", insertInto: ccmContext)
    let ccmMetadata2 = CCMValidatedMetadata(phoneNumber: global2, hashedGlobalNumber: "", insertInto: ccmContext)
    let ccmContact1 = CCMContact(insertInto: ccmContext)
    let ccmContact2 = CCMContact(insertInto: ccmContext)

    ccmContact1.displayName = "Rick"
    ccmContact2.displayName = "Morty"
    ccmPhone1.cachedValidatedMetadata = ccmMetadata1
    ccmPhone2.cachedValidatedMetadata = ccmMetadata2
    ccmPhone1.cachedContact = ccmContact1
    ccmPhone2.cachedContact = ccmContact2

    // when
    mockDBMgr.performContactMatch(with: mockContactCacheMgr, in: context)

    // then
    XCTAssertNotNil(ckmPhone2?.counterparty)
    XCTAssertEqual(ckmPhone2?.counterparty?.name, "Morty")
  }
}
