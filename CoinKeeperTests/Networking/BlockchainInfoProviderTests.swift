//
//  BlockchainInfoProviderTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Moya
import XCTest

class BlockchainInfoProviderTests: XCTestCase {

  var sut: BlockchainInfoProvider!

  override func setUp() {
    super.setUp()
    self.sut = MockBlockchainInfoProvider()
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
    (sut as? MockBlockchainInfoProvider)?.shouldSucceed = false

    sut.confirmFailedTransaction(with: badTxid)
      .done { didConfirm in
        XCTAssertTrue(didConfirm, "Failure confirmation should be true for an invalid txid")
        expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 10.0)
  }

}

class MockBlockchainInfoProvider: BlockchainInfoProvider {

  var shouldSucceed = true

  private var mockResponse: Data {
    let encoder = JSONEncoder()
    let response = BCITransactionResponse(hash: "test", time: 1)
    return (try? encoder.encode(response)) ?? "test".data(using: .utf8)!
  }

  override var provider: MoyaProvider<BlockchainInfoTarget> {
    let customEndpointClosure = { (target: BlockchainInfoTarget) -> Endpoint in
      return Endpoint(url: URL(target: target).absoluteString,
                      sampleResponseClosure: { () -> EndpointSampleResponse in
                        return self.shouldSucceed ?
                          .networkResponse(200, self.mockResponse) :
                          .networkResponse(500, self.mockResponse)
      },
                      method: target.method,
                      task: target.task,
                      httpHeaderFields: target.headers
      )
    }

    return MoyaProvider<BlockchainInfoTarget>.init(endpointClosure: customEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
  }
}
