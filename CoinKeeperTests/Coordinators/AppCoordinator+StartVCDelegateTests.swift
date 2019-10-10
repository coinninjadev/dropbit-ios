//
//  AppCoordinator+StartVCDelegateTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import MMDrawerController

class AppCoordinatorStartVCDelegateTests: XCTestCase {

  var sut: AppCoordinator!

  override func setUp() {
    super.setUp()
    self.sut = AppCoordinator()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testWhenPinCreatedLaunchStateManagerRequiresAuthentication() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    _ = mockPersistenceManager.keychainManager.store(valueToHash: "foo", key: .userPin)
    self.sut = AppCoordinator(persistenceManager: mockPersistenceManager, launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: self.sut.navigationController)
    let fakeVC = PlaceholderViewController.newInstance(delegate: nil)
    self.sut.navigationController.viewControllers = [fakeVC]
    mockLaunchStateManager.mockShouldRequireAuthentication = true

    self.sut.createWallet()

    XCTAssertTrue(mockLaunchStateManager.wasAskedForShouldRequireAuthentication, "should ask launchStateMgr if should auth")

    if let topVC = self.sut.navigationController.viewControllers.first {
      XCTAssertTrue(topVC is PinEntryViewController, "topVC should be PinEntryVC")
      XCTAssertTrue((topVC as? PinEntryViewController)?.delegate === self.sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("View Controllers should not be empty")
    }
  }

  func testCreatingWalletWhenDeviceNotVerifiedBehavesProperly() {
    let mockNavigationController = MockNavigationController()
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    self.sut = AppCoordinator(
      navigationController: mockNavigationController,
      persistenceManager: mockPersistenceManager,
      launchStateManager: mockLaunchStateManager
    )
    let startVC = StartViewController.newInstance(delegate: nil)
    mockNavigationController.viewControllers = [startVC]

    self.sut.createWallet()

    let expectation = XCTestExpectation(description: "pin entry")

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssertTrue(mockNavigationController.pushedViewController is PinCreationViewController,
                    "pushed view controller should be PinCreationViewController")

      let viewController = mockNavigationController.pushedViewController as? PinCreationViewController
      XCTAssertTrue(viewController?.entryDelegate === self.sut, "entryDelegate should be sut")
      XCTAssertTrue(viewController?.verificationDelegate === self.sut, "verificationDelegate should be sut")

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2)
  }

  func testCreatingWalletWhenOnboardingFlowCompletedPopsToRoot() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    mockNavigationController.viewControllers = [StartViewController.newInstance(delegate: nil)]
    mockLaunchStateManager.mockShouldRequireAuthentication = false
    mockLaunchStateManager.deviceIsVerifiedValue = true
    mockLaunchStateManager.shouldNeedUpgradeToSegwit = false

    self.sut = AppCoordinator(navigationController: mockNavigationController,
                              persistenceManager: mockPersistenceManager,
                              launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: mockNavigationController)

    self.sut.start()

    XCTAssertTrue(mockNavigationController.viewControllers.first is MMDrawerController, "nav vc first should be drawer")
    XCTAssertEqual(mockNavigationController.viewControllers.count, 1, "nav vc count should be 1")
  }
}
