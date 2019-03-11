//
//  NetworkManagerIntegrationTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
@testable import DropBit
import Moya
import XCTest

/// Runs tests that provide the MockCoinNinjaProvider with response data
/// and status codes to simulate actual server responses.
class NetworkManagerIntegrationTests: XCTestCase {

  var sut: NetworkManager!
  var persistenceManager: PersistenceManagerType!
  var cnProvider: MockCoinNinjaProvider!

  override func setUp() {
    super.setUp()
    persistenceManager = MockPersistenceManager()
    cnProvider = MockCoinNinjaProvider()
    self.sut = NetworkManager(persistenceManager: self.persistenceManager,
                              analyticsManager: MockAnalyticsManager(),
                              coinNinjaProvider: cnProvider)
  }

  override func tearDown() {
    self.sut = nil
    self.persistenceManager = nil
    self.cnProvider = nil
    super.tearDown()
  }

  func testNegativeTransactionPriceThrowsError() {
    let response = PriceTransactionResponse(average: -100)
    cnProvider.appendResponseStub(data: response.asData())

    let expectation = XCTestExpectation(description: "throw error for negative price")

    self.sut.fetchDayAveragePrice(for: "")
      .done { _ in
        XCTFail("Should not return valid response")
      }.catch { error in
        let expectedPath = PriceTransactionResponseKey.average.path
        let expectedValue = String(response.average)

        guard let networkError = error as? CKNetworkError,
          case let .invalidValue(path, value, _) = networkError else {
            XCTFail("Received incorrect error: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(expectedPath, path, "Error path should be \(expectedPath)")
        XCTAssertEqual(expectedValue, value, "Error value should be \(expectedValue)")

        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testMaxFeesThrowsError() {
    let sample = CheckInResponse.sampleInstance()!
    let invalidFee = FeesResponse.validFeeCeiling + 1
    let testFees = FeesResponse(max: 1, avg: 1, min: invalidFee)
    let testCheckInResponse = CheckInResponse(blockheight: sample.blockheight, fees: testFees, pricing: sample.pricing)
    cnProvider.appendResponseStub(data: testCheckInResponse.asData())

    let expectation = XCTestExpectation(description: "throw error for max fees")

    self.sut.walletCheckIn()
      .done { _ in
        XCTFail("Should not return valid response")
      }.catch { error in
        let expectedPath = FeesResponseKey.min.path
        let expectedValue = String(testCheckInResponse.fees.min)

        guard let networkError = error as? CKNetworkError,
          case let .invalidValue(path, value, _) = networkError else {
            XCTFail("Received incorrect error: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(expectedPath, path, "Error path should be \(expectedPath)")
        XCTAssertEqual(expectedValue, value, "Error value should be \(expectedValue)")

        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testEmptyStringWalletAddressThrowsError() {
    let sample = WalletAddressResponse.sampleInstance()!
    let emptyWalletAddress = WalletAddressResponse(id: sample.id,
                                                   createdAt: sample.createdAt,
                                                   updatedAt: sample.updatedAt,
                                                   address: "",
                                                   addressPubkey: sample.addressPubkey,
                                                   walletId: sample.walletId)
    let validWalletAddress = sample
    let responseListWithEmptyAddress = [emptyWalletAddress, validWalletAddress].asData()
    cnProvider.appendResponseStub(data: responseListWithEmptyAddress)

    let expectation = XCTestExpectation(description: "throw error for empty string as address")
    self.sut.getWalletAddresses()
      .done { _ in
        XCTFail("Should not return valid response")
      }
      .catch { error in
        guard let networkError = error as? CKNetworkError,
          case .invalidValue = networkError else {
            XCTFail("Received incorrect error: \(error.localizedDescription)")
            return
        }

        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

}
