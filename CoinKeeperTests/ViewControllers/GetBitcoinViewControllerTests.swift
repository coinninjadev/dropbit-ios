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
    sut = GetBitcoinViewController.newInstance(delegate: mockCoordinator, viewModels: [], bitcoinAddress: "")
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.tableView)
  }

}

class MockGetBitcoinViewControllerDelegate: GetBitcoinViewControllerDelegate {

  func openURL(_ url: URL, completionHandler completion: CKCompletion?) {}

  func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) {}

  var wasAskedToCopyAddress = false
  func viewControllerDidCopyAddress(_ viewController: UIViewController) {
    wasAskedToCopyAddress = true
  }

  var wasAskedToFindATMNearMe = false
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController) {
    wasAskedToFindATMNearMe = true
  }

  var wasAskedToBuyWithApplePay = false
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, bitcoinAddress url: String) {
    wasAskedToBuyWithApplePay = true
  }
}
