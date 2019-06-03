//
//  DrawerViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 4/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class SettingsViewControllerTests: XCTestCase {
  var sut: SettingsViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    sut = SettingsViewController.newInstance(with: mockCoordinator)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.settingsTableView, "settingsTableView should be connected")
    XCTAssertNotNil(self.sut.deleteWalletButton, "deleteWalletButton should be connected")
    XCTAssertNotNil(self.sut.resyncBlockchainButton, "resyncBlockchainButton should be connected")
  }

  // MARK: initial state
  func testTableViewDelegateDataSourceAreConnected() {
    XCTAssertTrue(self.sut.settingsTableView.delegate === sut, "delegate should be sut")
    XCTAssertTrue(self.sut.settingsTableView.dataSource === sut, "dataSource should be sut")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let actions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(SettingsViewController.close).description
    XCTAssertTrue(actions.contains(closeSelector), "closeButton should contain action")
  }

  func testDeleteWalletButtonContainsAction() {
    let actions = sut.deleteWalletButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SettingsViewController.deleteWallet(_:)).description
    XCTAssertTrue(actions.contains(selector), "deleteWalletButton should contain action")
  }

  func testResyncBlockchainButtonContainsAction() {
    let actions = sut.resyncBlockchainButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SettingsViewController.resyncBlockchain(_:)).description
    XCTAssertTrue(actions.contains(selector), "resyncBlockchainButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTellsDelegate() {
    sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didSelectCloseWasCalled, "should tell delegate that close was tapped")
  }

  func testResyncBlockchainButtonTellsDelegate() {
    sut.resyncBlockchainButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.resyncBlockchainWasCalled, "should tell delegate that resync blockchain was tapped")
  }

  func testDeleteWalletButtonTellsDelegate() {
    sut.deleteWalletButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.deleteWalletWasRequested, "should tell delegate to delete wallet")
  }

  // MARK: mock coordinator
  class MockCoordinator: SettingsViewControllerDelegate {

    func verifiedPhoneNumber() -> String? {
      return nil
    }

    func verifyIfWordsAreBackedUp() -> Bool {
      return false
    }

    func dustProtectionIsEnabled() -> Bool {
      return false
    }

    func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController) {}

    var deleteWalletWasRequested = false
    func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController, completion: @escaping () -> Void) {
      deleteWalletWasRequested = true
    }
    func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController) {}
    func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL) {}
    func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController) {}
    func viewControllerSendDebuggingInfo(_ viewController: UIViewController) { }
    func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController) {}
    func viewController(_ viewController: UIViewController, didEnableDustProtection didEnable: Bool) {}
    func viewController(_ viewController: UIViewController, didEnableYearlyHighNotification didEnable: Bool) {}

    var didSelectCloseWasCalled = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      didSelectCloseWasCalled = true
    }

    var resyncBlockchainWasCalled = false
    func viewControllerResyncBlockchain(_ viewController: UIViewController) {
      resyncBlockchainWasCalled = true
    }

    func yearlyHighPushNotificationIsSubscribed() -> Bool {
      return true
    }
  }
}
