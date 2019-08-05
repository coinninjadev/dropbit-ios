//
//  LaunchStateManagerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class LaunchStateManagerTests: MockedPersistenceTestCase {
  var sut: LaunchStateManager!

  override func setUp() {
    super.setUp()

    self.sut = LaunchStateManager(persistenceManager: mockPersistenceManager)
  }

  override func tearDown() {
    self.mockPersistenceManager = nil
    self.sut = nil
    super.tearDown()
  }

  func testCallingUserWasAuthenticatedSetsValue() {
    // initial assertions
    XCTAssertFalse(self.sut.userAuthenticated, "userAuthenticated should initially be false")

    // when
    self.sut.userWasAuthenticated()

    // then
    XCTAssertTrue(self.sut.userAuthenticated, "userAuthenticated should change to true")
  }

  func testCallingUnauthenticateUserSetsValue() {
    self.sut.userWasAuthenticated()  // set user to authenticated

    // initial assertions
    XCTAssertTrue(self.sut.userAuthenticated, "userAuthenticated should initially be true")

    // when
    self.sut.unauthenticateUser()

    // then
    XCTAssertFalse(self.sut.userAuthenticated, "userAuthenticated should change to false")
  }

  // MARK: initial state
  func testShouldRequireAuthenticationInitialState() {
    self.sut.unauthenticateUser()
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .deviceID)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)

    XCTAssertFalse(self.sut.shouldRequireAuthentication, "shouldRequireAuthentication should initially be false")
  }

  func testLaunchStateWhenPinEntered() {
    _ = mockPersistenceManager.keychainManager.store(valueToHash: "fake pin", key: .userPin)
    _ = mockPersistenceManager.keychainManager.store(anyValue: "fake phone ID", key: .deviceID)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)
    self.sut.unauthenticateUser()

    XCTAssertTrue(self.sut.shouldRequireAuthentication, "shouldRequireAuthentication should be true")

    // if user is already authenticated
    self.sut.userWasAuthenticated()
    XCTAssertFalse(self.sut.shouldRequireAuthentication, "shouldRequireAuthentication should be false if user is authenticated")
  }

  func testLaunchStateWhenWalletExistsShouldRequireAuthentication() {
    _ = mockPersistenceManager.keychainManager.store(valueToHash: "fake pin", key: .userPin)
    _ = mockPersistenceManager.keychainManager.store(anyValue: "fake phone ID", key: .deviceID)
    _ = mockPersistenceManager.keychainManager.store(anyValue: "fake wallet words", key: .walletWords)
    self.sut.unauthenticateUser()

    XCTAssertTrue(self.sut.shouldRequireAuthentication, "shouldRequireAuthentication should be true if user was unauthenticated")

    self.sut.userWasAuthenticated()
    XCTAssertFalse(self.sut.shouldRequireAuthentication, "shouldRequireAuthentication should be false if authenticated")
  }

  func testAfteriCloudRestoreWhenVerifiedReturnsPhoneRestore() {
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .deviceID)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)
    self.sut.unauthenticateUser()

    (mockPersistenceManager.databaseManager as? MockPersistenceDatabaseManager)?.walletIdToReturn = "foo"
    XCTAssertTrue(self.sut.isFirstTimeAfteriCloudRestore())
  }

  func testAfteriCloudRestoreWhenNotVerifiedPropertiesAreEmpty() {
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .deviceID)
    _ = mockPersistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)
    self.sut.unauthenticateUser()

    mockBrokers.mockUser.userVerificationStatusValue = .unverified

    XCTAssertTrue(self.sut.currentProperties().isEmpty)
  }
}
