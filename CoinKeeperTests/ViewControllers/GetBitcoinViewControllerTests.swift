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
    sut = GetBitcoinViewController.makeFromStoryboard()
    mockCoordinator = MockGetBitcoinViewControllerDelegate()
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
    XCTAssertNotNil(sut.findATMButton)
    XCTAssertNotNil(sut.buyWithCreditCardButton)
    XCTAssertNotNil(sut.buyWithGiftCardButton)
  }

  // MARK: buttons contain actions
  func testFindATMButtonContainsAction() {
    let actions = sut.findATMButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.findATM).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testBuyWithCreditCardButtonContainsAction() {
    let actions = sut.buyWithCreditCardButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.buyWithCreditCard).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testBuyWithGiftCardButtonContainsAction() {
    let actions = sut.buyWithGiftCardButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(GetBitcoinViewController.buyWithGiftCard).description
    XCTAssertTrue(actions.contains(expected))
  }

  // MARK: actions produce results
  func testFindATMTellsCoordinator() {
    sut.findATMButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToFindATMNearMe)
  }

  func testBuyWithCreditCardTellsCoordinator() {
    sut.buyWithCreditCardButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToBuyWithCreditCard)
  }

  func testBuyWithGiftCardTellsCoordinator() {
    sut.buyWithGiftCardButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToBuyWithGiftCard)
  }

}

class MockGetBitcoinViewControllerDelegate: GetBitcoinViewControllerDelegate {
  var wasAskedToFindATMNearMe = false
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController) {
    wasAskedToFindATMNearMe = true
  }

  var wasAskedToBuyWithCreditCard = false
  func viewControllerBuyWithCreditCard(_ viewController: GetBitcoinViewController) {
    wasAskedToBuyWithCreditCard = true
  }

  var wasAskedToBuyWithGiftCard = false
  func viewControllerBuyWithGiftCard(_ viewController: GetBitcoinViewController) {
    wasAskedToBuyWithGiftCard = true
  }
}
