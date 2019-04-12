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
  var mockURLOpener: MockURLOpener!

  override func setUp() {
    super.setUp()
    sut = GetBitcoinViewController.makeFromStoryboard()
    mockURLOpener = MockURLOpener()
    sut.urlOpener = mockURLOpener
    _ = sut.view
  }

  override func tearDown() {
    mockURLOpener = nil
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
  func testFindATMOpensURL() {
    sut.findATMButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockURLOpener.wasAskedToOpenURL)
    XCTAssertEqual(mockURLOpener.requestedURL?.absoluteString ?? "", "https://www.coinninja.com/webview/load-map")
  }

  func testBuyWithCreditCardOpensURL() {
    sut.buyWithCreditCardButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockURLOpener.wasAskedToOpenURL)
    XCTAssertEqual(mockURLOpener.requestedURL?.absoluteString ?? "", "https://www.coinninja.com/buybitcoin/creditcards")
  }

  func testBuyWithGiftCardOpensURL() {
    sut.buyWithGiftCardButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockURLOpener.wasAskedToOpenURL)
    XCTAssertEqual(mockURLOpener.requestedURL?.absoluteString ?? "", "https://www.coinninja.com/buybitcoin/giftcards")
  }

}

class MockURLOpener: URLOpener {
  var wasAskedToOpenURL = false
  var requestedURL: URL?
  func openURL(_ url: URL, completionHandler completion: (() -> Void)?) {
    wasAskedToOpenURL = true
    requestedURL = url
  }
}
