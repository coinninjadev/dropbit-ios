//
//  LightningUpgradeStartViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import Cnlib

class LightningUpgradeStartViewControllerTests: XCTestCase {

  var sut: LightningUpgradeStartViewController!
  var coordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    coordinator = MockCoordinator()
    sut = LightningUpgradeStartViewController.newInstance(delegate: coordinator, nextStep: {})
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
    XCTAssertNotNil(sut.confirmNewWordsSelectionView)
    XCTAssertNotNil(sut.confirmNewWordsLabel)
    XCTAssertNotNil(sut.confirmNewWordsCheckboxBackgroundView)
    XCTAssertNotNil(sut.confirmNewWordsCheckmarkImage)
    XCTAssertNotNil(sut.confirmTransferFundsView)
    XCTAssertNotNil(sut.confirmTransferFundsLabel)
    XCTAssertNotNil(sut.confirmTransferFundsCheckboxBackgroundView)
    XCTAssertNotNil(sut.confirmTransferFundsCheckmarkImage)
  }

  // initial state
  func testActivityIndicatorStartsOnScreen() {
    XCTAssertEqual(sut.activityIndicatorBottomConstraint.constant, 50)
  }

  func testUpgradeButtonIsInitiallyDisabled() {
    XCTAssertFalse(sut.upgradeButton.isEnabled)
  }

  func testSelectionViewsAreInitiallyHidden() {
    XCTAssertTrue(sut.confirmTransferFundsView.isHidden)
    XCTAssertTrue(sut.confirmNewWordsSelectionView.isHidden)
  }

  // updates
  func testUpdatingBalanceUpdatesUI() {
    XCTAssertEqual(sut.activityIndicatorBottomConstraint.constant, 50)

    let coin = BTCMainnetCoin(purpose: 84)
    let rbfOption = RBFOption.allowed.value
    let data = CNBCnlibNewTransactionDataStandard("", coin, 0, 0, nil, 0, rbfOption)
    try? data?.generate()
    data.map { self.sut.updateUI(withTransactionData: $0.transactionData) }

    XCTAssertLessThan(sut.activityIndicatorBottomConstraint.constant, 0)
  }

  func testUpdatingBalanceWithAmountDisplaysValuesInLabels() {
    XCTAssertNil(sut.confirmTransferFundsLabel.text)
    XCTAssertNil(sut.confirmTransferFundsLabel.attributedText)

    CKUserDefaults().standardDefaults.set(10000, forKey: CKUserDefaults.Key.exchangeRateBTCUSD.defaultsString)
    let coin = BTCMainnetCoin(purpose: 49)
    let path = CNBCnlibNewDerivationPath(coin, 0, 0)!
    let utxo = CNBCnlibNewUTXO("abc123", 0, 100_000, path, nil, true)!
    let address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
    let data = CNBCnlibNewTransactionDataSendingMax(address, coin, 5, 500000)
    data?.add(utxo)
    try? data?.generate()
    data.map { self.sut.updateUI(withTransactionData: $0.transactionData) }

    let expectedString = "I understand that DropBit will be transferring my funds of $9.93 with a transaction fee of $0.07 to my upgraded wallet."
    let actualString = sut.confirmTransferFundsLabel.attributedText?.string ?? ""
    XCTAssertEqual(actualString, expectedString)
    XCTAssertFalse(sut.confirmTransferFundsView.isHidden)
    XCTAssertFalse(sut.confirmNewWordsSelectionView.isHidden)
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
    var nextStepWasCalled = false
    sut.nextStep = { nextStepWasCalled = true }
    sut.upgradeNow(sut.upgradeButton)
    XCTAssertTrue(nextStepWasCalled)
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
    func viewControllerRequestedUpgradeAuthentication(_ viewController: LightningUpgradeStartViewController, completion: @escaping CKCompletion) {
      upgradeNowTapped = true
      completion()
    }
  }
}
