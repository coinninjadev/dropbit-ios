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

  override func setUp() {
    super.setUp()
    self.sut = SettingsViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.settingsTitleLabel, "settingsTitleLabel should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.settingsTableView, "settingsTableView should be connected")
    XCTAssertNotNil(self.sut.deleteWalletButton, "deleteWalletButton should be connected")
    XCTAssertNotNil(self.sut.resyncBlockchainButton, "resyncBlockchainButton should be connected")
    XCTAssertNotNil(self.sut.sendDebuggingInfoButton, "sendDebuggingInfoButton should be connected")
  }

  // MARK: initial state
  func testTableViewDelegateDataSourceAreConnected() {
    XCTAssertNotNil(self.sut.settingsTableView.delegate, "tableView delegate should not be nil")
    XCTAssertNotNil(self.sut.settingsTableView.dataSource, "tableView dataSource should not be nil")
    XCTAssertTrue(self.sut.settingsTableView.delegate === self.sut, "delegate should be sut")
    XCTAssertTrue(self.sut.settingsTableView.dataSource === self.sut, "dataSource should be sut")
    XCTAssertFalse(self.sut.resyncBlockchainButton.isHidden, "sync blockchain button should be visible by default")
    XCTAssertTrue(self.sut.sendDebuggingInfoButton.isHidden, "send debugging button should be hidden by default")
  }

  func testSupportModeInitialState() {
    sut.mode = .support
    sut.viewDidLoad() // call again to invoke simulating view loading
    XCTAssertTrue(self.sut.resyncBlockchainButton.isHidden, "sync blockchain button should be visible by default")
    XCTAssertFalse(self.sut.sendDebuggingInfoButton.isHidden, "send debugging button should be hidden by default")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let actions = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(SettingsViewController.closeButtonWasTouched).description
    XCTAssertTrue(actions.contains(closeSelector), "closeButton should contain action")
  }

  func testDeleteWalletButtonContainsAction() {
    let actions = self.sut.deleteWalletButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SettingsViewController.deleteWallet(_:)).description
    XCTAssertTrue(actions.contains(selector), "deleteWalletButton should contain action")
  }

  func testResyncBlockchainButtonContainsAction() {
    let actions = self.sut.resyncBlockchainButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SettingsViewController.resyncBlockchain(_:)).description
    XCTAssertTrue(actions.contains(selector), "resyncBlockchainButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTellsDelegate() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator

    sut.closeButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didSelectCloseWasCalled, "should tell delegate that close was tapped")
  }

  func testResyncBlockchainButtonTellsDelegate() {
    let mockCoordinator = MockCoordinator()
    sut.generalCoordinationDelegate = mockCoordinator

    sut.resyncBlockchainButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.resyncBlockchainWasCalled, "should tell delegate that resync blockchain was tapped")
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
    func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController, completion: @escaping () -> Void) {}
    func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController) {}
    func viewControllerDidRequestOpenURL(_ viewController: UIViewController, url: URL) {}
    func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController) {}
    func viewControllerSendDebuggingInfo(_ viewController: UIViewController) { }
    func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController) {}
    func viewControllerDidChangeDustProtection(_ viewController: UIViewController, shouldEnable: Bool) {}

    var didSelectCloseWasCalled = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      didSelectCloseWasCalled = true
    }

    var resyncBlockchainWasCalled = false
    func viewControllerResyncBlockchain(_ viewController: UIViewController) {
      resyncBlockchainWasCalled = true
    }

  }
}
