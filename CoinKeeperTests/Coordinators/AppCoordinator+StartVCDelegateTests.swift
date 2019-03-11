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

  func testWhenNoPinCreatedPushesPinCreationToNav() {
    let mockNavigationController = MockNavigationController()
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.nextLaunchStep = .enterPin
    self.sut = AppCoordinator(
      navigationController: mockNavigationController,
      persistenceManager: mockPersistenceManager,
      launchStateManager: mockLaunchStateManager
    )

    self.sut.createWallet()

    XCTAssertTrue(mockNavigationController.pushedViewController is PinCreationViewController, "pushed vc should be PinCreationVC")

    if let pinCreationVC = mockNavigationController.pushedViewController as? PinCreationViewController {
      XCTAssertTrue(pinCreationVC.coordinationDelegate === self.sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("pushed vc should be PinCreationVC")
    }
  }

  func testWhenPinCreatedLaunchStateManagerRequiresAuthentication() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.nextLaunchStep = .createWallet
    _ = mockPersistenceManager.keychainManager.store(valueToHash: "foo", key: .userPin)
    self.sut = AppCoordinator(persistenceManager: mockPersistenceManager, launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: self.sut.navigationController)
    let fakeVC = PlaceholderViewController.makeFromStoryboard()
    self.sut.navigationController.viewControllers = [fakeVC]
    mockLaunchStateManager.mockShouldRequireAuthentication = true

    self.sut.createWallet()

    XCTAssertTrue(mockLaunchStateManager.wasAskedForShouldRequireAuthentication, "should ask launchStateMgr if should auth")

    if let topVC = self.sut.navigationController.viewControllers.first {
      XCTAssertTrue(topVC is PinEntryViewController, "topVC should be PinEntryVC")
      XCTAssertTrue((topVC as? PinEntryViewController)?.coordinationDelegate === self.sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("View Controllers should not be empty")
    }
  }

  func testWhenCreatingWalletLaunchStateManagerDoesNotRequireAuth() {
    // user is already authenticated
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.nextLaunchStep = .createWallet
    _ = mockPersistenceManager.keychainManager.store(valueToHash: "foo", key: .userPin)

    let mockNavigationController = MockNavigationController()
    mockNavigationController.viewControllers = [StartViewController.makeFromStoryboard()]
    mockLaunchStateManager.mockShouldRequireAuthentication = false

    mockLaunchStateManager.nextLaunchStep = .createWallet
    self.sut = AppCoordinator(navigationController: mockNavigationController, launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: mockNavigationController)
    self.sut.start()

    self.sut.createWallet()

    XCTAssertTrue(mockNavigationController.pushedViewController is RecoveryWordsIntroViewController, "pushes CreateRecoveryWordsVC to the stack")
  }

  func testCreatingWalletWhenDeviceNotVerifiedBehavesProperly() {
    let mockNavigationController = MockNavigationController()
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.nextLaunchStep = .verifyDevice
    self.sut = AppCoordinator(
      navigationController: mockNavigationController,
      persistenceManager: mockPersistenceManager,
      launchStateManager: mockLaunchStateManager
    )
    let startVC = StartViewController.makeFromStoryboard()
    mockNavigationController.viewControllers = [startVC]

    self.sut.createWallet()

    XCTAssertTrue(mockNavigationController.pushedViewController is DeviceVerificationViewController, "pushedVC should be DeviceVerificationVC")

    let viewController = mockNavigationController.pushedViewController as? DeviceVerificationViewController
    XCTAssertTrue(viewController?.coordinationDelegate === self.sut.childCoordinators.first, "coordinationDelegate should be sut")
  }

  func testCreatingWalletWhenOnboardingFlowCompletedPopsToRoot() {
    let mockPersistenceManager = MockPersistenceManager()
    mockPersistenceManager.setDidTutorial(true)
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    mockNavigationController.viewControllers = [StartViewController.makeFromStoryboard()]
    mockLaunchStateManager.mockShouldRequireAuthentication = false

    mockLaunchStateManager.nextLaunchStep = .enterApp
    self.sut = AppCoordinator(navigationController: mockNavigationController,
                              persistenceManager: mockPersistenceManager,
                              launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: mockNavigationController)

    self.sut.start()

    XCTAssertTrue(mockNavigationController.viewControllers.first is MMDrawerController, "nav vc first should be drawer")
    XCTAssertEqual(mockNavigationController.viewControllers.count, 1, "nav vc count should be 1")
  }
}
