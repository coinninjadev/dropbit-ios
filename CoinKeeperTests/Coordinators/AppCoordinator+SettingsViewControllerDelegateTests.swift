//
//  AppCoordinator+SettingsViewControllerDelegateTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 12/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

// swiftlint:disable type_name
class AppCoordinatorSettingsViewControllerDelegateTests: XCTestCase {

  var sut: AppCoordinator!
  var mockSerialQueueManager: MockSerialQueueManager = MockSerialQueueManager()

  override func setUp() {
    super.setUp()
    sut = AppCoordinator(serialQueueManager: mockSerialQueueManager)
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testResyncBlockchainAddsOperationToQueue() {
    self.sut.viewControllerResyncBlockchain(UIViewController())
    XCTAssertTrue(mockSerialQueueManager.enqueueWalletSyncIfAppropriateWasCalled)
  }

}
