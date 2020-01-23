//
//  AppCoordinator+SendPaymentViewControllerDelegateTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 1/7/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

//swiftlint:disable:next type_name
class AppCoordinatorSendPaymentViewControllerDelegateTests: XCTestCase {

  var sut: AppCoordinator!
  var walletManager: WalletManagerType?

  override func setUp() {
    super.setUp()
    let mockPersistenceManager = MockPersistenceManager()
    mockPersistenceManager.fakeCoinToUse = BTCMainnetCoin(purpose: .segwit)
    let words = TestHelpers.abandonAbandon()
    walletManager = WalletManager(words: words, persistenceManager: mockPersistenceManager)!
    sut = AppCoordinator()
    sut.walletManager = walletManager
  }

  override func tearDown() {
    walletManager = nil
    sut = nil
    super.tearDown()
  }

  func testLNDecodingWithValidInvoice() {
    // swiftlint:disable line_length
    let invoiceString = "lightning:lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp"
    let url = LightningURL(string: invoiceString)!
    let expectedNumSatoshis = 250000
    let expectedDescription = "1 cup coffee"
    let expectedExpirationDate = DateComponents(calendar: Calendar.current, timeZone: .utc, year: 2017, month: 6, day: 1, hour: 10, minute: 58, second: 38).date ?? Date()
    let exp = expectation(description: "ln decode valid invoice")

    sut.viewControllerDidReceiveLightningURLToDecode(url)
      .done { (response: LNDecodePaymentRequestResponse) in
        XCTAssertEqual(response.numSatoshis ?? 0, expectedNumSatoshis)
        XCTAssertEqual(response.description ?? "", expectedDescription)
        XCTAssertTrue(response.isExpired)
        XCTAssertEqual(response.expiresAt, expectedExpirationDate)
      }
      .catch { (error: Error) in XCTFail(error.localizedDescription) }
      .finally { exp.fulfill() }

    waitForExpectations(timeout: 3.0)
  }

  func testLNDecodingWithInvalidInvoice() {
    // swiftlint:disable line_length
    let invoiceString = "lightning:lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rsp"
    let url = LightningURL(string: invoiceString)!
    let exp = expectation(description: "ln decode invalid invoice")

    sut.viewControllerDidReceiveLightningURLToDecode(url)
      .done { (_) in XCTFail("parsing should fail with checksum failed message") }
      .catch { (error: Error) in
        let expectedMessage = "checksum failed"
        XCTAssertTrue(error.localizedDescription.contains(expectedMessage))
      }
      .finally { exp.fulfill() }

    waitForExpectations(timeout: 3.0)
  }
}
