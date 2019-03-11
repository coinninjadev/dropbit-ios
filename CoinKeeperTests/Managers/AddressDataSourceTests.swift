//
//  AddressDataSourceTests.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import CNBitcoinKit
import XCTest

class AddressDataSourceTests: XCTestCase {

  var sut: AddressDataSource!

  override func tearDown() {
    super.tearDown()
    self.sut = nil
  }

  func testNextAvailableReceiveIndex_firstReturns0() {
    let context = InMemoryCoreDataStack().context
    let mockPersistence = MockPersistenceManager()
    mockPersistence.lastReceiveAddressIndexValue = -1
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 0, "First receive index should be 0")
  }

  func testNextAvailableReceiveIndex_after1Returns2() {
    let context = InMemoryCoreDataStack().context
    let mockPersistence = MockPersistenceManager()
    mockPersistence.lastReceiveAddressIndexValue = 1
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 2, "Index after 1 should be 2")
  }

  func testNextAvailableReceiveIndex_skipsContiguousIndices() {
    let context = InMemoryCoreDataStack().context
    let mockPersistence = MockPersistenceManager()
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [0, 1], in: context)

    XCTAssertEqual(nextIndex, 2, "First receive index after skip should be 2")
  }

  func testNextAvailableReceiveIndex_skips6() {
    let context = InMemoryCoreDataStack().context
    let mockPersistence = MockPersistenceManager()
    mockPersistence.lastReceiveAddressIndexValue = 5
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [6], in: context)

    XCTAssertEqual(nextIndex, 7, "Index after 5 skipping 6 should be 7")
  }

  func testNextAvailableReceiveIndex_returnsNoncontiguousSkipIndices() {
    let context = InMemoryCoreDataStack().context
    let mockPersistence = MockPersistenceManager()
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [0, 1, 4], in: context)

    XCTAssertEqual(nextIndex, 2, "First receive index after skip should be 2")
  }

  func testNextAvailableReceiveIndex_returnsMinGapIndex() {
    let context = InMemoryCoreDataStack().context
    let mockDefaults = MockPersistenceManager.MockPersistenceUserDefaultsManager()
    mockDefaults.receiveAddressIndexGapsValue = [3, 8, 20]
    let mockPersistence = MockPersistenceManager(userDefaultsManager: mockDefaults)
    mockPersistence.lastReceiveAddressIndexValue = 21
    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 3, "Should return min gap index of 3")
  }

  func testNextAvailableReceiveAddresses_skipsPendingDropBitAddresses() {
    let context = InMemoryCoreDataStack().context
    let mockDefaults = MockPersistenceManager.MockPersistenceUserDefaultsManager()
    mockDefaults.receiveAddressIndexGapsValue = []
    let mockPersistence = MockPersistenceManager(userDefaultsManager: mockDefaults)
    mockPersistence.lastReceiveAddressIndexValue = 0

    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)

    let dropBitIndices = [1, 2]
    let dropBitAddresses = dropBitIndices.compactMap { sut.receiveAddress(at: $0).address }
    mockPersistence.addressValuesForReceivedPendingDropBits = dropBitAddresses
    let expectedAddress = sut.receiveAddress(at: 3).address

    let nextAddress = sut.nextAvailableReceiveAddress(forServerPool: false, in: context)?.address ?? "-"

    XCTAssertEqual(expectedAddress, nextAddress, "Should return address at first index after DropBit addresses")
  }

  func testNextAvailableReceiveIndex_handlesAllSourcesCombined() {
    let context = InMemoryCoreDataStack().context
    let mockDefaults = MockPersistenceManager.MockPersistenceUserDefaultsManager()
    mockDefaults.receiveAddressIndexGapsValue = [3, 4, 6, 12]
    let mockPersistence = MockPersistenceManager(userDefaultsManager: mockDefaults)
    mockPersistence.lastReceiveAddressIndexValue = 15

    sut = AddressDataSource(wallet: CNBHDWallet(), persistenceManager: mockPersistence)

    let dropBitIndices = [3, 4] // two DropBits matching first two gaps
    let dropBitAddresses = dropBitIndices.compactMap { sut.receiveAddress(at: $0).address }
    mockPersistence.addressValuesForReceivedPendingDropBits = dropBitAddresses

    let expectedIndices = [6, 12, 16, 17]
    let expectedAddresses = expectedIndices.compactMap { sut.receiveAddress(at: $0).address }.asSet()

    let nextCNBMetaAddresses = sut.nextAvailableReceiveAddresses(number: 4, forServerPool: true, in: context)
    let nextAddresses = nextCNBMetaAddresses.compactMap { $0.address }.asSet()

    XCTAssertEqual(expectedAddresses, nextAddresses, "Next addresses should match the expected addresses")
  }

}
