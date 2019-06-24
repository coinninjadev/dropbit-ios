//
//  NetworkManagerTests.swift
//  DropBitTests
//
//  Created by Bill Feth on 4/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit
@testable import DropBit
import Moya
import XCTest

class NetworkManagerTests: XCTestCase {
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
    super.tearDown()
  }

  // MARK: initialization
  func testFetchingLatestExchangeRatesAfterInitializationRetrievesCachedValue() {
    self.sut.start()
    var rates: ExchangeRates = [:]
    let expectedRate = self.persistenceManager.brokers.checkIn.cachedBTCUSDRate
    self.sut.latestExchangeRates { (ratesParam) in
      rates = ratesParam
    }

    XCTAssertEqual(rates[.USD], expectedRate, "usd rate should equal expected rate")
  }

  // MARK: fees
  func testFetchingFeesAfterInitializationRetreivesCachedValue() {
    self.sut.start()
    let expectedBestFee = self.persistenceManager.brokers.checkIn.cachedBestFee
    let expectedBetterFee = self.persistenceManager.brokers.checkIn.cachedBetterFee
    let expectedGoodFee = self.persistenceManager.brokers.checkIn.cachedGoodFee

    let expectation = XCTestExpectation(description: "cached fees")
    _ = self.sut.latestFees()
      .done { fees in
        XCTAssertEqual(fees[.best], expectedBestFee, "best fee should equal expected value")
        XCTAssertEqual(fees[.better], expectedBetterFee, "better fee should equal expected value")
        XCTAssertEqual(fees[.good], expectedGoodFee, "good fee should equal expected value")
        expectation.fulfill()
      }.catch { error in
        XCTFail(error.localizedDescription)
    }

    wait(for: [expectation], timeout: 3.0)
  }

  // MARK: fetching exchange rates
  func testCheckingInForLatestMetadataExecutesCallback() {
    CKNotificationCenter.subscribe(self, [.didUpdateExchangeRates: #selector(self.exchangeRateNotificationHandler)])
    self.exchangeRateCallbackSucceeded = false

    if let response = try? JSONDecoder().decode(CheckInResponse.self, from: CheckInResponse.sampleData) {
      _ = self.sut.handleCheckIn(response: response)
    } else {
      XCTFail("failed to parse json for CheckinResponse")
    }

    XCTAssertTrue(self.exchangeRateCallbackSucceeded, "callback should be executed after fetching rates")

    CKNotificationCenter.unsubscribe(self)
  }

  var exchangeRateCallbackSucceeded: Bool = false
  func exchangeRateNotificationHandler() {
    exchangeRateCallbackSucceeded = true
  }

  func testCoinNinjaProviderHeaderDelegateIsSet() {
    XCTAssertNotNil(cnProvider.headerDelegate, "CoinNinjaProvider headerDelegate should not be nil")
  }

}
