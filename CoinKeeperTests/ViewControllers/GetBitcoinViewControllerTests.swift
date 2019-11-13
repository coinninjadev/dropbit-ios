//
//  GetBitcoinViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class GetBitcoinViewControllerTests: XCTestCase {

  var sut: GetBitcoinViewController!
  var mockCoordinator: MockGetBitcoinViewControllerDelegate!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockGetBitcoinViewControllerDelegate()
    sut = GetBitcoinViewController.newInstance(delegate: mockCoordinator, bitcoinAddress: "")
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.findATMButton)
    XCTAssertNotNil(sut.centerStackView)
    XCTAssertNotNil(sut.purchaseBitcoinInfoLabel)
    XCTAssertNotNil(sut.copyBitcoinAddressButton)
    XCTAssertNotNil(sut.buyWithApplePayButton)
  }

  // MARK: buttons contain actions
  func testFindATMButtonContainsAction() {
    let actions = sut.findATMButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.findATM).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testBuyWithApplePayButtonContainsAction() {
    let actions = sut.buyWithApplePayButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.buyWithApplePay).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testBitcoinButtonContainsAction() {
    let actions = sut.copyBitcoinAddressButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.copyBitcoinAddress(_:)).description
    XCTAssertTrue(actions.contains(expected))
  }

  // MARK: actions produce results
  func testFindATMTellsCoordinator() {
    sut.findATMButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToFindATMNearMe)
  }

  func testCopyLightningAddressTellsCoordinator() {
    sut.copyBitcoinAddressButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToCopyAddress)
  }

  func testBuyWithApplePayTellsCoordinator() {
    sut.buyWithApplePayButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToBuyWithApplePay)
  }

}

class MockGetBitcoinViewControllerDelegate: GetBitcoinViewControllerDelegate {
  var wasAskedToCopyAddress = false
  func viewControllerDidCopyAddress(_ viewController: UIViewController) {
    wasAskedToCopyAddress = true
  }

  var wasAskedToFindATMNearMe = false
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController) {
    wasAskedToFindATMNearMe = true
  }

  var wasAskedToBuyWithApplePay = false
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, url: String) {
    wasAskedToBuyWithApplePay = true
  }
}
