//
//  LightningUpgradeStartViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class LightningUpgradeStartViewControllerTests: XCTestCase {

  var sut: LightningUpgradeStartViewController!
  var coordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    coordinator = MockCoordinator()
    sut = LightningUpgradeStartViewController.newInstance(withDelegate: coordinator)
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
    coordinator = nil
    super.tearDown()
  }

  // outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.overlayView)
    XCTAssertNotNil(sut.lightningTitleLabel)
    XCTAssertNotNil(sut.detailLabel)
    XCTAssertNotNil(sut.upgradeButton)
    XCTAssertNotNil(sut.infoButton)
    XCTAssertNotNil(sut.activityIndicator)
    XCTAssertNotNil(sut.activityIndicatorBottomConstraint)
  }

  // initial state
  func testActivityIndicatorStartsOnScreen() {
    XCTAssertEqual(sut.activityIndicatorBottomConstraint.constant, 50)
  }

  func testUpgradeButtonIsInitiallyDisabled() {
    XCTAssertFalse(sut.upgradeButton.isEnabled)
  }

  // updates
  func testUpdatingBalanceUpdatesUI() {
    XCTAssertEqual(sut.activityIndicatorBottomConstraint.constant, 50)

    sut.updateUI(withBalance: 0)

    XCTAssertLessThan(sut.activityIndicatorBottomConstraint.constant, 0)
//    XCTAssertTrue(sut.activityIndicator.isHidden)
//    XCTAssertTrue(sut.upgradeButton.isEnabled)
  }

  // buttons contain actions
  func testUpgradeButtonContainsAction() {
    let actions = sut.upgradeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let action = #selector(sut.upgradeNow(_:)).description
    XCTAssertTrue(actions.contains(action))
  }

  func testInfoButtonContainsAction() {
    let actions = sut.infoButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let action = #selector(sut.showInfo(_:)).description
    XCTAssertTrue(actions.contains(action))
  }

  // actions produce results
  func testUpgradeButtonTellsDelegate() {
    sut.upgradeNow(sut.upgradeButton)
    XCTAssertTrue(coordinator.upgradeNowTapped)
  }

  func testShowInfoButtonTellsDelegate() {
    sut.showInfo(sut.infoButton)
    XCTAssertTrue(coordinator.showInfoTapped)
  }

  // private mock coordinator class
  class MockCoordinator: LightningUpgradeStartViewControllerDelegate {
    var showInfoTapped = false
    func viewControllerRequestedShowLightningUpgradeInfo(_ viewController: LightningUpgradeStartViewController) {
      showInfoTapped = true
    }

    var upgradeNowTapped = false
    func viewControllerRequestedUpgradeToLightning(_ viewController: LightningUpgradeStartViewController) {
      upgradeNowTapped = true
    }
  }
}
