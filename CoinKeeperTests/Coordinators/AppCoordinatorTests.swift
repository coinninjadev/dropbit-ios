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

// swiftlint:disable file_length
class AppCoordinatorTests: XCTestCase {
  var sut: AppCoordinator!

  override func setUp() {
    super.setUp()
    self.sut = AppCoordinator()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: calling start
  @discardableResult
  private func setupStart() -> (MockLaunchStateManager, MockAnalyticsManager) {
    let mockPersistenceManager = MockPersistenceManager()
    let mockAnalyticsManager = MockAnalyticsManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.mockShouldRequireAuthentication = false
    mockLaunchStateManager.skippedVerificationValue = false
    mockLaunchStateManager.deviceIsVerifiedValue = false

    let nav = CNNavigationController(rootViewController: StartViewController.makeFromStoryboard())
    self.sut = AppCoordinator(navigationController: nav,
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

    self.sut.start()

    XCTAssertTrue(self.sut.navigationController.topViewController is StartViewController, "topViewController should be a StartViewController")

    if let startVC = self.sut.navigationController.topViewController as? StartViewController {
      XCTAssertTrue(startVC.coordinationDelegate === self.sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("topViewController should be a StartViewController")
    }

    XCTAssertTrue(mockAnalyticsManager.startWasCalled, "analytics manager should start")
  }

  func testOperationQueueHasOneMaxConcurrentOperation() {
    XCTAssertEqual(self.sut.serialQueueManager.queue.maxConcurrentOperationCount, 1)
  }

  // MARK: pin entered

  func testCallingStartWhenDeviceVerifiedBehavesProperly() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    mockLaunchStateManager.deviceIsVerifiedValue = true
    let mockNavigationController = MockNavigationController()
    mockNavigationController.viewControllers = [StartViewController.makeFromStoryboard()]
    self.sut = AppCoordinator(navigationController: mockNavigationController,
                              persistenceManager: mockPersistenceManager,
                              launchStateManager: mockLaunchStateManager)
    TestHelpers.initializeWindow(with: mockNavigationController)
    self.sut.start()

    XCTAssertTrue(mockNavigationController.topViewController is MMDrawerController, "topVC should be an MMDrawerController")

    if let drawerVC = mockNavigationController.topViewController as? MMDrawerController,
      let centerVC = drawerVC.centerViewController as? TransactionHistoryViewController {
      XCTAssertTrue(centerVC.coordinationDelegate === self.sut, "coordinationDelegate should be sut")
    } else {
      XCTFail("centerViewController should be a TransactionHistoryViewController")
    }
  }

  // MARK: launch state manager
  func testCallingAppEnteredActiveStateAsksPersistenceManagerForLastLoginTimeForComparison() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    self.sut = AppCoordinator(persistenceManager: mockPersistenceManager, launchStateManager: mockLaunchStateManager)

    self.sut.appEnteredActiveState()

    XCTAssertTrue(mockPersistenceManager.wasAskedForLastLoginTime, "should ask persistenceManager for last login time")

    _ = mockPersistenceManager.setLastLoginTime()
    let lastLoginTime: TimeInterval = mockPersistenceManager.lastLoginTime()! - 60
    mockPersistenceManager.setLastMockLogin(timeInterval: lastLoginTime)

    self.sut.appEnteredActiveState()

    XCTAssertTrue(mockLaunchStateManager.wasAskedForShouldRequireAuthentication, "should ask launch state mgr to auth")
  }

  func testCallingAppResignedActiveTellsPersistenceManagerToSetCurrentTime() {
    let mockPersistenceManager = MockPersistenceManager()
    self.sut = AppCoordinator(persistenceManager: mockPersistenceManager)

    self.sut.appWillResignActiveState()

    XCTAssertTrue(mockPersistenceManager.setLastLoginTimeWasCalled, "should tell persistenceManager to set last login time")
  }

  func testCallingSuccessfullyAuthenticatedTellsLaunchStateManagerUserWasAuthenticated() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    self.sut = AppCoordinator(
      navigationController: mockNavigationController,
      launchStateManager: mockLaunchStateManager
    )
    mockLaunchStateManager.mockShouldRequireAuthentication = true
    UIApplication.shared.keyWindow?.rootViewController = self.sut.navigationController

    self.sut.appEnteredActiveState() // to call requireAuthentication...
    self.sut.viewControllerDidSuccessfullyAuthenticate(PinEntryViewController.makeFromStoryboard())

    XCTAssertTrue(mockLaunchStateManager.userWasAuthenticatedWasCalled, "should call userWasAuthenticated")
  }

  func testAfterPinCreatedAndVerifiedDismissesPinEntryVC() {
    let mockPersistenceManager = MockPersistenceManager()
    let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
    let mockNavigationController = MockNavigationController()
    let startVC = StartViewController.makeFromStoryboard()
    mockNavigationController.viewControllers = [startVC]
    mockLaunchStateManager.mockShouldRequireAuthentication = false

    self.sut.appEnteredActiveState() // to call requireAuthentication...
    self.sut.viewControllerDidSuccessfullyAuthenticate(PinEntryViewController.makeFromStoryboard())

    XCTAssertEqual(mockNavigationController.viewControllers.count, 1, "nav controller should only have 1 vc")
    XCTAssertTrue(mockNavigationController.viewControllers.first is StartViewController, "nav controller top vc should be StartVC")
  }

  private func mocksForTestingSyncRoutine() ->
    // swiftlint:disable:next large_tuple
    (persistence: MockPersistenceManager,
    launchState: MockLaunchStateManager,
    network: MockNetworkManager,
    wallet: MockWalletManager) {

      let mockPersistenceManager = MockPersistenceManager()
      mockPersistenceManager.walletIdValue = ""
      mockPersistenceManager.userIdValue = ""
      _ = mockPersistenceManager.keychainManager.store(recoveryWords: [""], isBackedUp: true)

      let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
      mockLaunchStateManager.userAuthenticatedValue = true
      mockLaunchStateManager.skippedVerificationValue = true
      mockLaunchStateManager.walletExistsValue = true

      let mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)

      let mockWalletManager = MockWalletManager(words: TestHelpers.fakeWords(), persistenceManager: mockPersistenceManager)

      return (mockPersistenceManager, mockLaunchStateManager, mockNetworkManager, mockWalletManager)
  }

  //swiftlint:disable large_tuple
  private func mocksForTestingUnverification(type: RecordType) ->
    (persistence: MockPersistenceManager,
    launchState: MockLaunchStateManager,
    network: MockNetworkManager,
    alert: MockAlertManager) {

      let mockPersistenceManager = MockPersistenceManager()
      mockPersistenceManager.walletIdValue = ""
      mockPersistenceManager.userIdValue = ""
      if type == .wallet {
        mockPersistenceManager.userIdValue = nil
      }

      _ = mockPersistenceManager.keychainManager.store(recoveryWords: [""], isBackedUp: true)
      mockPersistenceManager.userVerificationStatusValue = .verified

      let mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
      mockLaunchStateManager.userAuthenticatedValue = true
      mockLaunchStateManager.skippedVerificationValue = true
      mockLaunchStateManager.walletExistsValue = true

      let mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)
      let mockAlertManager = MockAlertManager(notificationManager:
        NotificationManager(permissionManager: PermissionManager(),
                            networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                              analyticsManager: AnalyticsManager())))

      return (mockPersistenceManager, mockLaunchStateManager, mockNetworkManager, mockAlertManager)
  }

  // MARK: sync routine
  func testSyncRoutineCallsGetUser() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetUser")
    let mocks = mocksForTestingSyncRoutine()

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    let completion: CompletionHandler = { error in
      XCTAssertTrue(mocks.network.getUserWasCalled, "syncTransactionDataAndServerAddresses should call getUser")
      expectation.fulfill()
    }
    self.sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                               completion: completion, fetchResult: nil)

    wait(for: [expectation], timeout: 10.0)
  }

  func testSyncRoutineCallsGetWallet() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()
    mocks.persistence.userIdValue = nil

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    let completion: CompletionHandler = { error in
      XCTAssertTrue(mocks.network.getWalletWasCalled, "syncTransactionDataAndServerAddresses should call getWallet")
      expectation.fulfill()
    }
    self.sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                               completion: completion, fetchResult: nil)

    wait(for: [expectation], timeout: 3.0)
  }

  func testSyncRoutineMissingWalletManagerRejectsWithError() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    self.sut.walletManager = nil

    self.sut.predefineSyncDependencies(in: self.sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
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
    mocks.launchState.userAuthenticatedValue = false

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    self.sut.walletManager = mocks.wallet

    self.sut.predefineSyncDependencies(in: self.sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
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
    mocks.launchState.skippedVerificationValue = false
    mocks.launchState.userAuthenticatedValue = false

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    self.sut.walletManager = mocks.wallet

    self.sut.predefineSyncDependencies(in: self.sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
      if let syncRoutineError = error as? SyncRoutineError {
        XCTAssertEqual(syncRoutineError, SyncRoutineError.notReady)
      } else {
        XCTFail("Error should be notReady")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testSyncRoutineMissingRecoveryWordsRejectsWithError() {
    let expectation = XCTestExpectation(description: "testSyncRoutineCallsGetWallet")
    let mocks = mocksForTestingSyncRoutine()
    _ = mocks.persistence.keychainManager.store(anyValue: nil, key: .walletWords)

    self.sut = AppCoordinator(persistenceManager: mocks.persistence,
                              launchStateManager: mocks.launchState,
                              networkManager: mocks.network)
    self.sut.walletManager = mocks.wallet

    self.sut.predefineSyncDependencies(in: self.sut.persistenceManager.createBackgroundContext(), inBackground: false).catch { error in
      if let syncRoutineError = error as? SyncRoutineError {
        XCTAssertEqual(syncRoutineError, SyncRoutineError.missingRecoveryWords)
      } else {
        XCTFail("Error should be missingRecoveryWords")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }

  // MARK: delegates
  func testDelegateRelationshipsAreSet() {
    XCTAssertNotNil(self.sut.notificationManager.delegate, "NotificationManager delegate should not be nil")
    XCTAssertNotNil(self.sut.networkManager.headerDelegate, "NetworkManager headerDelegate should not be nil")
    XCTAssertNotNil(self.sut.networkManager.walletDelegate, "NetworkManager walletDelegate should not be nil")
    XCTAssertNotNil(self.sut.alertManager.urlOpener, "AlertManager urlOpener should not be nil")
  }

  func testCheckAndRecoverAuthorizationIds_authorizationErrorUnverifiesUser() {
    let expectation = XCTestExpectation(description: "authorizationErrorUnverifiesUser")
    let userMocks = mocksForTestingUnverification(type: .user)

    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)
    userMocks.network.getUserError = .shouldUnverify(moyaError, .user)

    self.sut = AppCoordinator(persistenceManager: userMocks.persistence,
                              launchStateManager: userMocks.launchState,
                              alertManager: userMocks.alert,
                              networkManager: userMocks.network)

    let completion: CompletionHandler = { _ in
      XCTAssert(userMocks.persistence.unverifyUserWasCalled, "should call unverifyUser")
      XCTAssert(userMocks.alert.showBannerWithMessageDurationAlertKindWasCalled, "should call showBanner")
      expectation.fulfill()
    }

    self.sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                               completion: completion, fetchResult: nil)
    wait(for: [expectation], timeout: 3.0)
  }

  func testCheckAndRecoverAuthorizationIds_authorizationErrorRemovesWalletId() {
    let expectation = XCTestExpectation(description: "authorizationErrorRemovesWalletId")
    let walletMocks = mocksForTestingUnverification(type: .wallet)

    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)
    walletMocks.network.getWalletError = .shouldUnverify(moyaError, .wallet)

    self.sut = AppCoordinator(persistenceManager: walletMocks.persistence,
                              launchStateManager: walletMocks.launchState,
                              alertManager: walletMocks.alert,
                              networkManager: walletMocks.network)

    let completion: CompletionHandler = { _ in
      XCTAssert(walletMocks.persistence.unverifyUserWasCalled, "should call unverifyUser")
      XCTAssert(walletMocks.persistence.removeWalletIdWasCalled, "should call removeWalletId")
      XCTAssert(walletMocks.alert.showBannerWithMessageDurationAlertKindWasCalled, "should call showBanner")
      expectation.fulfill()
    }

    self.sut.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                               completion: completion, fetchResult: nil)
    wait(for: [expectation], timeout: 3.0)
  }

  // MARK: create wallet action
  //  override func spec() {
  //    describe("AppCoordinator") {
  //      context("calling pinWasFullyEntered(digits:)") {
  //        var fakeDigits: String = ""
  //        beforeEach {
  //          fakeDigits = Array(repeating: "1", count: 6).joined()
  //          self.sut.pinWasFullyEntered(digits: fakeDigits)
  //        }
  //        afterEach {
  //          self.sut.navigationController.popViewController(animated: false)
  //        }
  //        it("presents a new PinCreationVC") {
  //          expect(self.sut.navigationController.topViewController).to(beAKindOf(PinCreationViewController.self))
  //        }
  //        it("passes digits to entryMode's associated value") {
  //          guard let pinVC = self.sut.navigationController.topViewController as? PinCreationViewController else {
  //            fail("nav top viewController should be PinCreationViewController")
  //            return
  //          }
  //          switch pinVC.entryMode {
  //          case .pinVerification(let digits): expect(digits).to(equal(fakeDigits))
  //          default: fail("entryMode should be pinVerification")
  //          }
  //        }
  //        it("assigns self as verificationDelegate") {
  //          let pinVC = self.sut.navigationController.topViewController as? PinCreationViewController
  //          expect(pinVC?.verificationDelegate).to(beIdenticalTo(self.sut))
  //        }
  //      }
  //
  //      context("calling pinWasVerified(digits:)") {
  //        var mockPersistenceManager: MockPersistenceManager!
  //        var mockLaunchStateManager: MockLaunchStateManager!
  //        var expectedValue = ""
  //        var fakeDigits: String = ""
  //        beforeEach {
  //          mockPersistenceManager = MockPersistenceManager()
  //          mockLaunchStateManager = MockLaunchStateManager(persistenceManager: mockPersistenceManager)
  //          mockLaunchStateManager.mockShouldRequireAuthentication = false
  //          self.sut = AppCoordinator(persistenceManager: mockPersistenceManager, launchStateManager: mockLaunchStateManager)
  //          self.sut.navigationController.pushViewController(StartViewController.makeFromStoryboard(), animated: false)
  //          let digit = "5"
  //          fakeDigits = Array(repeating: digit, count: 6).joined()
  //          expectedValue = fakeDigits
  //        }
  //        it("persists pin to keychain") {
  //          let mockKeychainManager = mockPersistenceManager.keychainManager as? MockPersistenceManager.MockPersistenceKeychainManager
  //          expect(mockKeychainManager?.valueExists).to(beFalse())
  //          self.sut.pinWasVerified(digits: fakeDigits)
  //          expect(mockKeychainManager?.valueExists).to(beTrue())
  //
  //          let actualValue = mockKeychainManager?.retrieveValue(for: .userPin) as? String
  //          expect(actualValue).to(equal(expectedValue))
  //        }
  //        context("biometric authentication") {
  //          var mockBiometricManager: MockBiometricAuthenticationManager!
  //          beforeEach {
  //            mockBiometricManager = MockBiometricAuthenticationManager()
  //            mockPersistenceManager = MockPersistenceManager()
  //            self.sut = AppCoordinator(persistenceManager: mockPersistenceManager, biometricsAuthenticationManager: mockBiometricManager)
  //            let digit = "5"
  //            fakeDigits = Array(repeating: digit, count: 6).joined()
  //          }
  //          context("with successful authentication") {
  //            beforeEach {
  //              mockBiometricManager.mockShouldAuthenticateWithBiometrics = true
  //              self.sut.pinWasVerified(digits: fakeDigits)
  //            }
  //            it("calls completion handler") { expect(mockBiometricManager.completionWasCalled).to(beTrue()) }
  //          }
  //          context("with unsuccessful authentication") {
  //            beforeEach {
  //              mockBiometricManager.mockShouldAuthenticateWithBiometrics = false
  //              self.sut.pinWasVerified(digits: fakeDigits)
  //            }
  //            it("calls error handler") { expect(mockBiometricManager.errorWasCalled).to(beTrue()) }
  //          }
  //        }
  //      }
  //
  //      context("calling checkMatch(for: )") {
  //        var expectedDigits: String = ""
  //        let matchingDigit = "4"
  //        let nonMatchingDigit = "3"
  //        var isMatching: Bool?
  //        beforeEach {
  //          expectedDigits = Array(repeating: matchingDigit, count: 6).joined()
  //          let mockPersistenceManager = MockPersistenceManager()
  //          self.sut = AppCoordinator(persistenceManager: mockPersistenceManager)
  //          _ = self.sut.persistenceManager.keychainManager.store(valueToHash: expectedDigits.sha256(), key: .userPin)
  //        }
  //        context("with matching digits") {
  //          beforeEach {
  //            let matching = Array(repeating: matchingDigit, count: 6).joined()
  //            isMatching = self.sut.checkMatch(for: matching)
  //          }
  //          it("returns true") { expect(isMatching).to(beTrue()) }
  //        }
  //        context("with mismatched digits") {
  //          beforeEach {
  //            let nonMatching = Array(repeating: nonMatchingDigit, count: 6).joined()
  //            isMatching = self.sut.checkMatch(for: nonMatching)
  //          }
  //          it("returns false") { expect(isMatching).to(beFalse()) }
  //        }
  //        context("when digits don't exist") { // shouldn't happen
  //          beforeEach {
  //            _ = self.sut.persistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
  //          }
  //          it("returns false") { expect(self.sut.checkMatch(for: expectedDigits)).to(beFalse()) }
  //        }
  //      }
  //
  //      context("calling tryBiometrics") {
  //        var mockBiometricsManager: MockBiometricAuthenticationManager!
  //        beforeEach {
  //          mockBiometricsManager = MockBiometricAuthenticationManager()
  //          self.sut = AppCoordinator(biometricsAuthenticationManager: mockBiometricsManager)
  //          self.sut.viewControllerDidTryBiometrics(PinEntryViewController.makeFromStoryboard())
  //        }
  //        it("asks biometrics auth mgr if it can authenticate") {
  //          expect(mockBiometricsManager.canAuthenticateWithBiometricsWasCalled).to(beTrue())
  //        }
  //        context("when able to auth via biometrics") {
  //          beforeEach {
  //            mockBiometricsManager.mockShouldAuthenticateWithBiometrics = true
  //            self.sut.viewControllerDidTryBiometrics(PinEntryViewController.makeFromStoryboard())
  //          }
  //          it("asks biometric auth mgr to authenticate") {
  //            expect(mockBiometricsManager.authenticateWasCalled).to(beTrue())
  //          }
  //        }
  //      }
  //
  //      context("calling verifyWords(words:)") {
  //        var mockNavigationController: MockNavigationController!
  //        beforeEach {
  //          mockNavigationController = MockNavigationController(rootViewController: StartViewController.makeFromStoryboard())
  //          self.sut = AppCoordinator(navigationController: mockNavigationController)
  //          self.sut.start()
  //          self.sut.verifyWords(words: TestHelpers.fakeWords())
  //        }
  //        it("pushes verify words view controller onto nav stack") {
  //          expect(mockNavigationController.pushedViewController).to(beAnInstanceOf(VerifyRecoveryWordsViewController.self))
  //        }
  //      }
  //
  //      context("VerifyRecoveryWordsViewControllerDelegate actions") {
  //        context("calling wordVerificationSucceeded") {
  //          var mockNavigationController: MockNavigationController!
  //          var mockPersistenceManager: PersistenceManager!
  //          var mockKeychainAccessor: MockKeychainAccessorType!
  //          beforeEach {
  //            mockKeychainAccessor = MockKeychainAccessorType()
  //            let keychainManager = PersistenceManager.Keychain(store: mockKeychainAccessor)
  //            mockPersistenceManager = PersistenceManager(keychainManager: keychainManager)
  //            mockNavigationController = MockNavigationController()
  //            self.sut = AppCoordinator(navigationController: mockNavigationController, persistenceManager: mockPersistenceManager)
  //            TestHelpers.initializeWindow(with: self.sut.navigationController)
  //            self.sut.navigationController.viewControllers = [StartViewController.makeFromStoryboard()]
  //            self.sut.wordVerificationSucceeded(for: TestHelpers.fakeWords())
  //          }
  //          it("removes onboarding VCs from nav stack and only has 1") {
  //            expect(mockNavigationController.innerViewControllers.count).to(equal(1))
  //          }
  //          it("stores words in keychain") {
  //            expect(mockKeychainAccessor?.wasAskedToArchive).to(beTrue())
  //          }
  //        }
  //        context("calling wordVerificationFailed") {
  //          var mockAlertManager: MockAlertManager!
  //          beforeEach {
  //            mockAlertManager = MockAlertManager()
  //            self.sut = AppCoordinator(alertManager: mockAlertManager)
  //            self.sut.wordVerificationFailed()
  //          }
  //          it("asks alertManager for an alert object") {
  //            expect(mockAlertManager.wasAskedForAlert).to(beTrue())
  //          }
  //        }
  //        context("calling wordVerificationMaxFailuresAttempted") {
  //          var mockAlertManager: MockAlertManager!
  //          beforeEach {
  //            mockAlertManager = MockAlertManager()
  //            self.sut = AppCoordinator(alertManager: mockAlertManager)
  //            self.sut.wordVerificationMaxFailuresAttempted()
  //          }
  //          it("asks alertManager for an alert object") {
  //            expect(mockAlertManager.wasAskedForAlert).to(beTrue())
  //          }
  //        }
  //      }
  //      context("DeviceVerificationViewControllerDelegate actions") {
  //        context("calling didEnterCode") {
  //          var mockNavigationController: MockNavigationController!
  //          var mockPersistenceManager: PersistenceManager!
  //          var mockKeychainAccessor: MockKeychainAccessorType!
  //          var mockNetworkManager: NetworkManagerType!
  //          var mockTelephonyDataController: TelephonyDataControllerType!
  //          beforeEach {
  //            mockKeychainAccessor = MockKeychainAccessorType()
  //            let keychainManager = PersistenceManager.Keychain(store: mockKeychainAccessor)
  //            mockPersistenceManager = PersistenceManager(keychainManager: keychainManager)
  //            mockNavigationController = MockNavigationController()
  //            mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager)
  //            mockTelephonyDataController = MockTelephonyDataController()
  //            self.sut = AppCoordinator(navigationController: mockNavigationController,
  //                                      persistenceManager: mockPersistenceManager,
  //                                      networkManager: mockNetworkManager)
  //            TestHelpers.initializeWindow(with: self.sut.navigationController)
  //            let deviceVerificationCoordinator = DeviceVerificationCoordinator(mockNavigationController)
  //            self.sut.startChildCoordinator(childCoordinator: deviceVerificationCoordinator)
  //
  //            let deviceVerificationViewController = DeviceVerificationViewController.makeFromStoryboard()
  //            self.sut.navigationController.viewControllers = [deviceVerificationViewController]
  //
  //            deviceVerificationCoordinator.viewController(deviceVerificationViewController, didEnterPhoneNumber: "3305555555")
  //            deviceVerificationCoordinator.viewController(deviceVerificationViewController, didEnterCode: "123456") { _ in
  //            }
  //          }
  //          it("removes onboarding VCs from nav stack and only has 1") {
  //            expect(mockNavigationController.innerViewControllers.count).to(equal(1))
  //          }
  //          it("only has Drawer Controller in nav stack viewControllers") {
  //            expect(mockNavigationController.viewControllers.count).to(equal(1))
  //          }
  //        }
  //      }
  //
  //      context("RequestPayViewControllerDelegate methods") {
  //        context("calling viewControllerSuccessfullyCopiedToClipboard") {
  //          var mockAlertManager: MockAlertManager!
  //          beforeEach {
  //            mockAlertManager = MockAlertManager()
  //            self.sut = AppCoordinator(alertManager: mockAlertManager)
  //            self.sut.viewControllerSuccessfullyCopiedToClipboard(self.sut.navigationController) // send nav only to satisfy params
  //          }
  //          it("tells alert manager to show success") {
  //            expect(mockAlertManager.wasAskedToShowSuccessMessage).to(beTrue())
  //          }
  //        }
  //      }
  //    }
  //  }

}

extension PinEntryViewController {
  override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    completion?()
  }
}

class MockAlertManager: AlertManagerType {
  var urlOpener: URLOpener?

  func showBanner(with message: String, duration: AlertDuration?) {}

  func alert(from viewModel: AlertControllerViewModel) -> AlertControllerType {
    return alert(withTitle: viewModel.title,
                 description: viewModel.description,
                 image: viewModel.image,
                 style: viewModel.style,
                 actionConfigs: viewModel.actions)
  }

  var showBannerWithMessageDurationAlertKindWasCalled = false
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind) {
    showBannerWithMessageDurationAlertKindWasCalled = true
  }
  func showBannerAlert(for response: MessageResponse, completion: (() -> Void)?) {}

  func defaultAlert(withTitle title: String, description: String?) -> AlertControllerType {
    let alertManager = AlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    return alertManager.alert(withTitle: title, description: description, image: nil, style: .alert, actionConfigs: [])
  }

  func showBanner(with message: String, duration: AlertDuration) { }
  func showBanner(with message: String, duration: AlertDuration, alertKind kind: CKBannerViewKind) { }
  func showBanner(with message: String, alertKind kind: CKBannerViewKind) { }
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind, tapAction: (() -> Void)?) {}
  func showAlert(for update: AddressRequestUpdateDisplayable) { }

  func alert(withTitle title: String,
             description: String?,
             image: UIImage?,
             style: AlertManager.AlertStyle,
             buttonLayout: AlertManagerButtonLayout,
             actionConfigs: [AlertActionConfigurationType]) -> AlertControllerType {
    let alertManager = AlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    return alertManager.alert(withTitle: title, description: description, image: image, style: style, actionConfigs: [])
  }

  func detailedAlert(withTitle title: String?,
                     description: String?,
                     image: UIImage,
                     style: AlertMessageStyle,
                     action: AlertActionConfigurationType
    ) -> AlertControllerType {
    let alertManager = AlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    return alertManager.detailedAlert(withTitle: title, description: description, image: image, style: style, action: action)
  }

  func didTapBanner(_ bannerView: CKBannerView) {}
  func didTapClose(_ bannerView: CKBannerView) {}

  var wasAskedForAlert = false
  func alert(withTitle title: String,
             description: String?,
             image: UIImage?,
             style: AlertManager.AlertStyle,
             actionConfigs: [AlertActionConfigurationType]) -> AlertControllerType {

    wasAskedForAlert = true
    let alertManager = AlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    return alertManager.alert(withTitle: title, description: description, image: image, style: style, actionConfigs: [])
  }

  var notificationManager: NotificationManagerType

  required init(notificationManager: NotificationManagerType) {
    self.notificationManager = notificationManager
  }

  var wasAskedToShowSuccessMessage = false
  func showSuccess(message: String, forDuration duration: TimeInterval?) {
    wasAskedToShowSuccessMessage = true
  }

  func showError(message: String, forDuration duration: TimeInterval?) {
  }

  var wasAskedToShowActivityHUD = false
  func showActivityHUD(withStatus status: String?) {
    wasAskedToShowActivityHUD = true
  }

  var wasAskedToHideActivityHUD = false
  func hideActivityHUD(withDelay delay: TimeInterval?, completion: (() -> Void)?) {
    wasAskedToHideActivityHUD = true
  }

  func showSuccessHUD(withStatus status: String?, duration: TimeInterval, completion: (() -> Void)?) { }

  func showIncomingTransactionAlert(for receivedAmount: Int, with rates: ExchangeRates) { }

}
