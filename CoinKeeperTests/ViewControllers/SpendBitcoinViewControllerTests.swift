//
//  SpendBitcoinViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SpendBitcoinViewControllerTests: XCTestCase {
  var sut: SpendBitcoinViewController!
  var mockCoordinator: MockSpendBitcoinViewControllerDelegate!

  override func setUp() {
    super.setUp()
    sut = SpendBitcoinViewController.makeFromStoryboard()
    mockCoordinator = MockSpendBitcoinViewControllerDelegate()
    sut.generalCoordinationDelegate = mockCoordinator
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.headerLabel)
    XCTAssertNotNil(sut.cardCollectionView)
    XCTAssertNotNil(sut.spendAroundMeButton)
    XCTAssertNotNil(sut.spendOnlineButton)
  }

  // MARK: buttons contain actions
  func testSpendAroundMeButtonContainsAction() {
    let actions = sut.spendAroundMeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(SpendBitcoinViewController.spendBitcoinAroundMe(_:)).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testSpendOnlineButtonContainsAction() {
    let actions = sut.spendOnlineButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(SpendBitcoinViewController.spendBitcoinOnline(_:)).description
    XCTAssertTrue(actions.contains(expected))
  }

  // MARK: actions produce results
  func testSpendAroundMeButtonTellsCoordinator() {
    sut.spendAroundMeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToSpendBitcoinAroundMe)
  }

  func testSpendOnlineButtonTellsCoordinator() {
    sut.spendOnlineButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToSpendBitcoinOnline)
  }

  func testSpendGiftCardsTellsCoordinator() {
    sut.collectionView(sut.cardCollectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
    XCTAssertTrue(mockCoordinator.wasAskedToSpendGiftCards)
    XCTAssertTrue(mockCoordinator.wasAskedToSuspendAuthentication)
  }
}

class MockSpendBitcoinViewControllerDelegate: SpendBitcoinViewControllerDelegate {
  var wasAskedToSpendBitcoinAroundMe = false
  func viewControllerSpendBitcoinAroundMe(_ viewController: SpendBitcoinViewController) {
    wasAskedToSpendBitcoinAroundMe = true
  }

  var wasAskedToSpendGiftCards = false
  func viewControllerSpendGiftCards(_ viewController: SpendBitcoinViewController) {
    wasAskedToSpendGiftCards = true
  }

  var wasAskedToSpendBitcoinOnline = false
  func viewControllerSpendBitcoinOnline(_ viewController: SpendBitcoinViewController) {
    wasAskedToSpendBitcoinOnline = true
  }

  var suspendAuthenticationOnceUntil: Date?
  var wasAskedToSuspendAuthentication = false
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController) {
    wasAskedToSuspendAuthentication = true
  }
}
