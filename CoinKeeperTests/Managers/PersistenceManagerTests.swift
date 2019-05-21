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
  var mockKeychainManager: CKKeychain!
  var mockDatabaseManager: MockPersistenceDatabaseManager!
  var mockUserDefaultsManager: MockUserDefaultsManager!
  var mockContactCacheManager: MockContactCacheManager!

  override func setUp() {
    super.setUp()
    mockDatabaseManager = MockPersistenceDatabaseManager()
    mockContactCacheManager = MockContactCacheManager()
    mockKeychainAccessor = MockKeychainAccessorType()
    mockUserDefaultsManager = MockUserDefaultsManager()
    mockKeychainManager = CKKeychain(store: mockKeychainAccessor)

    self.sut = PersistenceManager(
      keychainManager: mockKeychainManager,
      databaseManager: mockDatabaseManager,
      userDefaultsManager: mockUserDefaultsManager,
      contactCacheManager: mockContactCacheManager
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
  private func setupKeychainTests() {
    let keychainManager = CKKeychain(store: mockKeychainAccessor)
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
    let mockDatabaseManager = MockPersistenceDatabaseManager()
    self.sut = PersistenceManager(databaseManager: mockDatabaseManager)

    _ = self.sut.deleteTransactions(notIn: [], in: InMemoryCoreDataStack().context)

    XCTAssertTrue(mockDatabaseManager.deleteTransactionsFromResponsesWasCalled, "should tell databaseManager to handle grooming")
  }

  // MARK: user defaults
  func testReceiveAddressIndexGaps() {
    XCTAssertTrue(sut.userDefaultsManager.receiveAddressIndexGaps.isEmpty, "receiveAddressIndexGaps should be empty at start of test")

    let expectedGaps = Set([1, 3, 5, 28])
    sut.userDefaultsManager.receiveAddressIndexGaps = expectedGaps

    XCTAssertEqual(sut.userDefaultsManager.receiveAddressIndexGaps, expectedGaps, "receiveAddressIndexGaps should equal the gaps that were set")
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
      userDefaultsManager: mockUserDefaultsManager,
      contactCacheManager: mockContactCacheMgr
    )

    let context = sut.mainQueueContext()

    // set up ckm data
    let global1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let global2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305557777")
    let ckmPhone1 = CKMPhoneNumber(phoneNumber: global1, insertInto: context)
    let ckmPhone2 = CKMPhoneNumber(phoneNumber: global2, insertInto: context)
    let counterparty1 = CKMCounterparty(name: "Rick", insertInto: context)
    ckmPhone1?.counterparty = counterparty1
    _ = ckmPhone1.map { counterparty1.phoneNumbers.insert($0) }

    // set up ccm data
    let ccmContext = mockContactCacheMgr.mainQueueContext
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
