//
//  MockedPersistenceTestCase.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class MockedPersistenceTestCase: XCTestCase {

  var mockBrokers: MockPersistenceBrokers!
  var mockPersistenceManager: MockPersistenceManager!
  var mockLaunchStateManager: MockLaunchStateManager!
  var mockDatabaseManager: MockPersistenceDatabaseManager!
  var mockUserDefaultsManager: MockUserDefaultsManager!

  override func setUp() {
    super.setUp()

    let inputs = MockPersistenceBrokerInputs.newInstance()
    mockDatabaseManager = inputs.mockDatabase
    mockUserDefaultsManager = inputs.mockDefaults

    mockBrokers = MockPersistenceBrokers(inputs: inputs)
    mockPersistenceManager = MockPersistenceManager(keychainManager: inputs.keychain,
                                                    databaseManager: inputs.database,
                                                    userDefaultsManager: inputs.defaults,
                                                    brokers: mockBrokers)
    mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
  }

  override func tearDown() {
    super.tearDown()
    mockBrokers = nil
    mockPersistenceManager = nil
    mockLaunchStateManager = nil
    mockDatabaseManager = nil
  }

}
