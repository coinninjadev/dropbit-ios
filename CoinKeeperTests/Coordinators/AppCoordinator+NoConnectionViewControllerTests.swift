//
//  AppCoordinator+NoConnectionViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class AppCoordinatorNoConnectionViewControllerTests: XCTestCase {

  var sut: AppCoordinator!
  var networkManager: MockNetworkManager!
  var connectionManager: MockConnectionManager!

  override func setUp() {
    super.setUp()
    let mockPersistenceManager = MockPersistenceManager()
    connectionManager = MockConnectionManager()
    networkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)
    sut = AppCoordinator(networkManager: networkManager, connectionManager: connectionManager)
    connectionManager.delegate = sut
  }

  override func tearDown() {
    super.tearDown()
  }

  func testRetryWithFailingConnection() {
    // given
    networkManager.walletCheckInShouldSucceed = false
    let expectation = XCTestExpectation(description: "failing connection")
    connectionManager.setAPIUnreachable(false) // set it to opposite of what will be asserted later

    // when
    sut.viewControllerDidRequestRetry(NoConnectionViewController.makeFromStoryboard()) {
      expectation.fulfill()
    }

    // then
    wait(for: [expectation], timeout: 2.0)
    XCTAssertTrue(connectionManager.apiUnreachable)
  }

  func testRetryWithSuccessfulConnection() {
    // given
    networkManager.walletCheckInShouldSucceed = true
    let expectation = XCTestExpectation(description: "succeeding connection")
    connectionManager.setAPIUnreachable(true) // set it to opposite of what will be asserted later

    // when
    sut.viewControllerDidRequestRetry(NoConnectionViewController.makeFromStoryboard()) {
      expectation.fulfill()
    }

    // then
    wait(for: [expectation], timeout: 2.0)
    XCTAssertFalse(connectionManager.apiUnreachable)
  }

}
