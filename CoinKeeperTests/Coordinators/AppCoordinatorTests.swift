//
//  AppCoordinatorTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest
import MMDrawerController

class AppCoordinatorTests: MockedPersistenceTestCase {
  var sut: AppCoordinator! {
    didSet {
      self.skipTwitterAuth()
    }
  }

  override func setUp() {
    super.setUp()
    sut = AppCoordinator(persistenceManager: mockPersistenceManager, launchStateManager: mockLaunchStateManager)
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  private func skipTwitterAuth() {
    sut?.twitterAccessManager.uiTestArguments = [.skipTwitterAuthentication]
  }

  // MARK: calling start
  @discardableResult
  private func setupStart() -> (MockLaunchStateManager, MockAnalyticsManager) {
    let mockAnalyticsManager = MockAnalyticsManager()
    mockLaunchStateManager.mockShouldRequireAuthentication = false
    mockLaunchStateManager.skippedVerificationValue = false
    mockLaunchStateManager.deviceIsVerifiedValue = false

    let nav = CNNavigationController(rootViewController: StartViewController.newInstance(delegate: nil))
    sut = AppCoordinator(navigationController: nav,
                         persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         analyticsManager: mockAnalyticsManager)
    TestHelpers.initializeWindow(with: nav)
    return (mockLaunchStateManager, mockAnalyticsManager)
  }

  // MARK: first time
  func testFirstTimeBehavior() {
    let (mockLaunchStateManager, mockAnalyticsManager) = setupStart()
    mockLaunchStateManager.mockShouldRequireAuthentication = false

    sut.start()

    XCTAssertTrue(sut.navigationController.topViewController is StartViewController, "topViewController should be a StartViewController")

    if let startVC = sut.navigationController.topViewController as? StartViewController {
      XCTAssertTrue(startVC.coordinationDelegate === sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("topViewController should be a StartViewController")
    }

    XCTAssertTrue(mockAnalyticsManager.startWasCalled, "analytics manager should start")
  }

  func testOperationQueueHasOneMaxConcurrentOperation() {
    XCTAssertEqual(sut.serialQueueManager.queue.maxConcurrentOperationCount, 1)
  }

  // MARK: pin entered

  func testCallingStartWhenDeviceVerifiedBehavesProperly() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.deviceIsVerifiedValue = true
    let mockNavigationController = MockNavigationController()
    mockNavigationController.viewControllers = [StartViewController.newInstance(delegate: nil)]
    sut = AppCoordinator(navigationController: mockNavigationController,
                         persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: mockNavigationController)
    sut.start()

    XCTAssertTrue(mockNavigationController.topViewController is MMDrawerController, "topVC should be an MMDrawerController")

    if let drawerVC = mockNavigationController.topViewController as? MMDrawerController,
      let centerVC = drawerVC.centerViewController as? WalletOverviewViewController {
      XCTAssertTrue(centerVC.coordinationDelegate === sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("centerViewController should be a TransactionHistoryViewController")
    }
  }

  // MARK: launch state manager
  func testCallingAppEnteredActiveStateAsksPersistenceManagerForLastLoginTimeForComparison() {

    sut.appEnteredActiveState()

    XCTAssertTrue(mockBrokers.mockActivity.wasAskedForLastLoginTime, "should ask activityBroker for last login time")

    _ = mockBrokers.mockActivity.setLastLoginTime()
    let lastLoginTime: TimeInterval = mockBrokers.mockActivity.lastLoginTime! - 60
    mockBrokers.mockActivity.setLastMockLogin(timeInterval: lastLoginTime)

    sut.appEnteredActiveState()

    XCTAssertTrue(mockLaunchStateManager.wasAskedForShouldRequireAuthentication, "should ask launch state mgr to auth")
  }

  func testCallingAppResignedActiveTellsPersistenceManagerToSetCurrentTime() {
    sut.appWillResignActiveState()

    XCTAssertTrue(mockBrokers.mockActivity.setLastLoginTimeWasCalled, "should tell persistenceManager to set last login time")
  }

  func testCallingSuccessfullyAuthenticatedTellsLaunchStateManagerUserWasAuthenticated() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    sut = AppCoordinator(
      navigationController: mockNavigationController,
      launchStateManager: mockLaunchStateManager
    )
    mockLaunchStateManager.mockShouldRequireAuthentication = true
    UIApplication.shared.keyWindow?.rootViewController = sut.navigationController

    sut.appEnteredActiveState() // to call requireAuthentication...
    let vc = sut.createPinEntryViewControllerForAppOpen(whenAuthenticated: {})
    vc.authenticationSatisfied()

    XCTAssertTrue(mockLaunchStateManager.userWasAuthenticatedWasCalled, "should call userWasAuthenticated")
  }

  func testAfterPinCreatedAndVerifiedDismissesPinEntryVC() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    let startVC = StartViewController.newInstance(delegate: nil)
    mockNavigationController.viewControllers = [startVC]
    mockLaunchStateManager.mockShouldRequireAuthentication = false

    sut.appEnteredActiveState() // to call requireAuthentication...
    let viewModel = OpenAppPinEntryViewModel()
    let vc = PinEntryViewController.newInstance(delegate: sut, viewModel: viewModel, success: nil)
    vc.authenticationSatisfied()

    XCTAssertEqual(mockNavigationController.viewControllers.count, 1, "nav controller should only have 1 vc")
    XCTAssertTrue(mockNavigationController.viewControllers.first is StartViewController, "nav controller top vc should be StartVC")
  }

  private func configurePersistenceMocksForTestingSyncRoutine() {
    mockBrokers.mockWallet.walletIdValue = ""
    mockBrokers.mockUser.userIdValue = ""
    _ = mockPersistenceManager.keychainManager.store(recoveryWords: [""], isBackedUp: true)
    mockLaunchStateManager.userAuthenticatedValue = true
    mockLaunchStateManager.skippedVerificationValue = true
    mockLaunchStateManager.walletExistsValue = true
  }

  private func mocksForTestingSyncRoutine() ->
    (network: MockNetworkManager,
    wallet: MockWalletManager) {
      configurePersistenceMocksForTestingSyncRoutine()

      let mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)
      let mockWalletManager = MockWalletManager(words: TestHelpers.fakeWords(), persistenceManager: mockPersistenceManager)
      return (mockNetworkManager, mockWalletManager)
  }

  /// Changes values on the mocks initialized during setUp()
  private func configurePersistenceMocksForTestingUnverification(type: RecordType) {
    mockBrokers.mockWallet.walletIdValue = ""
    mockBrokers.mockUser.userIdValue = ""
    if type == .wallet {
      mockBrokers.mockUser.userIdValue = nil
    }

    _ = mockPersistenceManager.keychainManager.store(recoveryWords: [""], isBackedUp: true)
    mockBrokers.mockUser.userVerificationStatusValue = .verified

    mockLaunchStateManager.userAuthenticatedValue = true
    mockLaunchStateManager.skippedVerificationValue = true
    mockLaunchStateManager.walletExistsValue = true
  }

  private func mocksForTestingUnverification() -> (network: MockNetworkManager, alert: MockAlertManager) {
    let mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)
    let mockAlertManager = MockAlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    return (mockNetworkManager, mockAlertManager)
  }

  // MARK: sync routine
  func testSyncRoutineCallsGetUser() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetUser")
    let mocks = mocksForTestingSyncRoutine()

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         networkManager: mocks.network)
    let completion: CKErrorCompletion = { error in
      XCTAssertTrue(mocks.network.getUserWasCalled, "syncTransactionDataAndServerAddresses should call getUser")
      expectation.fulfill()
    }
    sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                          completion: completion, fetchResult: nil)

    wait(for: [expectation], timeout: 10.0)
  }

  func testSyncRoutineCallsGetWallet() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()
    mockBrokers.mockUser.userIdValue = nil

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         networkManager: mocks.network)
    let completion: CKErrorCompletion = { error in
      XCTAssertTrue(mocks.network.getWalletWasCalled, "syncTransactionDataAndServerAddresses should call getWallet")
      expectation.fulfill()
    }
    sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                          completion: completion, fetchResult: nil)

    wait(for: [expectation], timeout: 3.0)
  }

  func testSyncRoutineMissingWalletManagerRejectsWithError() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")

    let mocks = mocksForTestingSyncRoutine()

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         networkManager: mocks.network)
    sut.walletManager = nil

    sut.predefineSyncDependencies(in: sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
      if let syncRoutineError = error as? SyncRoutineError {
        XCTAssertEqual(syncRoutineError, SyncRoutineError.missingWalletManager)
      } else {
        XCTFail("Error should be missingWalletManager")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testSyncRoutineUserNotAuthenticatedRejectsWithError() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()
    mockLaunchStateManager.userAuthenticatedValue = false

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         networkManager: mocks.network)
    sut.walletManager = mocks.wallet

    sut.predefineSyncDependencies(in: sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
      if let syncRoutineError = error as? SyncRoutineError {
        XCTAssertEqual(syncRoutineError, SyncRoutineError.notReady)
      } else {
        XCTFail("Error should be notReady")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testSyncRoutineNotReadyToEnterAppRejectsWithError() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()
    mockLaunchStateManager.skippedVerificationValue = false
    mockLaunchStateManager.userAuthenticatedValue = false

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         networkManager: mocks.network)
    sut.walletManager = mocks.wallet

    sut.predefineSyncDependencies(in: sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
      if let syncRoutineError = error as? SyncRoutineError {
        XCTAssertEqual(syncRoutineError, SyncRoutineError.notReady)
      } else {
        XCTFail("Error should be notReady")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  // MARK: delegates
  func testDelegateRelationshipsAreSet() {
    XCTAssertNotNil(sut.notificationManager.delegate, "NotificationManager delegate should not be nil")
    XCTAssertNotNil(sut.networkManager.headerDelegate, "NetworkManager headerDelegate should not be nil")
    XCTAssertNotNil(sut.networkManager.walletDelegate, "NetworkManager walletDelegate should not be nil")
    XCTAssertNotNil(sut.alertManager.urlOpener, "AlertManager urlOpener should not be nil")
  }

  func testCheckAndRecoverAuthorizationIds_authorizationErrorUnverifiesUser() {
    let expectation = XCTestExpectation(description: "authorizationErrorUnverifiesUser")
    configurePersistenceMocksForTestingUnverification(type: .user)
    let localMocks = mocksForTestingUnverification()
    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)
    localMocks.network.getUserError = .shouldUnverify(moyaError, .user)

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         alertManager: localMocks.alert,
                         networkManager: localMocks.network)

    let completion: CKErrorCompletion = { _ in
      XCTAssert(self.mockBrokers.mockUser.unverifyUserWasCalled, "should call unverifyUser")
      XCTAssert(localMocks.alert.showBannerWithMessageDurationAlertKindWasCalled, "should call showBanner")
      expectation.fulfill()
    }

    sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                          completion: completion, fetchResult: nil)
    wait(for: [expectation], timeout: 10.0)
  }

  func testCheckAndRecoverAuthorizationIds_authorizationErrorRemovesWalletId() {
    let expectation = XCTestExpectation(description: "authorizationErrorRemovesWalletId")
    configurePersistenceMocksForTestingUnverification(type: .wallet)
    let localMocks = mocksForTestingUnverification()

    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)
    localMocks.network.getWalletError = .shouldUnverify(moyaError, .wallet)

    sut = AppCoordinator(persistenceManager: mockPersistenceManager,
                         launchStateManager: mockLaunchStateManager,
                         alertManager: localMocks.alert,
                         networkManager: localMocks.network)

    let completion: CKErrorCompletion = { _ in
      XCTAssert(self.mockBrokers.mockUser.unverifyUserWasCalled, "should call unverifyUser")
      XCTAssert(self.mockBrokers.mockWallet.removeWalletIdWasCalled, "should call removeWalletId")
      XCTAssert(localMocks.alert.showBannerWithMessageDurationAlertKindWasCalled, "should call showBanner")
      expectation.fulfill()
    }

    sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                          completion: completion, fetchResult: nil)
    wait(for: [expectation], timeout: 10.0)
  }

}

extension PinEntryViewController {
  override public func dismiss(animated flag: Bool, completion: CKCompletion? = nil) {
    completion?()
  }
}
