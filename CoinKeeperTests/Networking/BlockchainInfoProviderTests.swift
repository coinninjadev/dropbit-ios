//
//  BlockchainInfoProviderTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class BlockchainInfoProviderTests: XCTestCase {

  var sut: BlockchainInfoProvider!

  override func setUp() {
    super.setUp()
    self.sut = BlockchainInfoProvider()
  }

  override func tearDown() {
    super.tearDown()
    self.sut = nil
  }

  func testConfirmFailedTransactionWithValidTxid() {
    let expectation = XCTestExpectation(description: "Confirmation should be false")

    let goodTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"

    sut.confirmFailedTransaction(with: goodTxid)
      .done { didConfirm in
        XCTAssertFalse(didConfirm, "Failure confirmation should be false for a valid txid")
        expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 10.0)
  }

  func testConfirmFailedTransactionWithInvalidTxid() {
    let expectation = XCTestExpectation(description: "Confirmation should be true")

    let badTxid = ""
    sut.confirmFailedTransaction(with: badTxid)
      .done { didConfirm in
        XCTAssertTrue(didConfirm, "Failure confirmation should be true for an invalid txid")
        expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 10.0)
  }

}
