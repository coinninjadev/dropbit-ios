//
//  AddressDataSourceTests.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Cnlib
import XCTest

class AddressDataSourceTests: MockedPersistenceTestCase {

  var sut: AddressDataSource!
  var mockDefaults: MockUserDefaultsManager {
    return mockUserDefaultsManager
  }

  override func setUp() {
    super.setUp()
    let coin = CNBCnlibNewBaseCoin(84, 0, 0)!
    let wallet = CNBCnlibNewHDWalletFromWords(TestHelpers.abandonAbandon().joined(separator: " "), coin)!
    sut = AddressDataSource(wallet: wallet, persistenceManager: mockPersistenceManager)
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testNextAvailableReceiveIndex_firstReturns0() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = -1
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 0, "First receive index should be 0")
  }

  func testNextAvailableReceiveIndex_after1Returns2() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = 1
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 2, "Index after 1 should be 2")
  }

  func testNextAvailableReceiveIndex_skipsContiguousIndices() {
    let context = InMemoryCoreDataStack().context
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [0, 1], in: context)

    XCTAssertEqual(nextIndex, 2, "First receive index after skip should be 2")
  }

  func testNextAvailableReceiveIndex_skips6() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = 5
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [6], in: context)

    XCTAssertEqual(nextIndex, 7, "Index after 5 skipping 6 should be 7")
  }

  func testNextAvailableReceiveIndex_returnsNoncontiguousSkipIndices() {
    let context = InMemoryCoreDataStack().context
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [0, 1, 4], in: context)

    XCTAssertEqual(nextIndex, 2, "First receive index after skip should be 2")
  }

  func testNextAvailableReceiveIndex_returnsMinGapIndex() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.receiveAddressIndexGapsValue = [3, 8, 20]
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = 21
    let nextIndex = sut.nextAvailableReceiveIndex(indicesToSkip: [], in: context)

    XCTAssertEqual(nextIndex, 3, "Should return min gap index of 3")
  }

  func testNextAvailableReceiveAddresses_skipsPendingDropBitAddresses() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.receiveAddressIndexGapsValue = []
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = 0

    let dropBitIndices = [1, 2]
    let dropBitAddresses = dropBitIndices.compactMap { try? sut.receiveAddress(at: $0).address }
    mockBrokers.mockInvitation.addressValuesForReceivedPendingDropBits = dropBitAddresses
    let expectedAddress = (try? sut.receiveAddress(at: 3).address) ?? ""

    let nextAddress = sut.nextAvailableReceiveAddress(forServerPool: false, in: context)?.address ?? "-"

    XCTAssertEqual(expectedAddress, nextAddress, "Should return address at first index after DropBit addresses")
  }

  func testNextAvailableReceiveIndex_handlesAllSourcesCombined() {
    let context = InMemoryCoreDataStack().context
    mockBrokers.mockWallet.receiveAddressIndexGapsValue = [3, 4, 6, 12]
    mockBrokers.mockWallet.lastReceiveAddressIndexValue = 15

    let dropBitIndices = [3, 4] // two DropBits matching first two gaps
    let dropBitAddresses = dropBitIndices.compactMap { try? sut.receiveAddress(at: $0).address }
    mockBrokers.mockInvitation.addressValuesForReceivedPendingDropBits = dropBitAddresses

    let expectedIndices = [6, 12, 16, 17]
    let expectedAddresses = expectedIndices.compactMap { try? sut.receiveAddress(at: $0).address }.asSet()

    let nextCNBMetaAddresses = sut.nextAvailableReceiveAddresses(number: 4, forServerPool: true, in: context)
    let nextAddresses = nextCNBMetaAddresses.compactMap { $0.address }.asSet()

    XCTAssertEqual(expectedAddresses, nextAddresses, "Next addresses should match the expected addresses")
  }

}
