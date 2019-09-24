//
//  ConfirmPaymentMemoViewTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 9/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class ConfirmPaymentMemoViewTests: XCTestCase {

  var sut: ConfirmPaymentMemoView!

  let frame = CGRect(x: 0, y: 0, width: 262, height: 75)

  override func setUp() {
    super.setUp()
    self.sut = ConfirmPaymentMemoView(frame: frame)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.topBackgroundView, "topBackgroundView should be connected")
    XCTAssertNotNil(self.sut.bottomBackgroundView, "bottomBackgroundView should be connected")
    XCTAssertNotNil(self.sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(self.sut.separatorView, "separatorView should be connected")
    XCTAssertNotNil(self.sut.sharedStatusImage, "sharedStatusImage should be connected")
    XCTAssertNotNil(self.sut.sharedStatusLabel, "sharedStatusLabel should be connected")
  }

  func testMemoPopulatesLabel() {
    let config = testMemoConfig()
    self.sut.configure(with: config)
    XCTAssertEqual(sut.memoLabel.text, config.memo)
  }

  func testIsSharedImage() {
    let config = testMemoConfig(isShared: true)
    self.sut.configure(with: config)
    XCTAssertEqual(sut.sharedStatusImage.image, sut.isSharedImage)
  }

  func testIsNotSharedImage() {
    let config = testMemoConfig(isShared: false)
    self.sut.configure(with: config)
    XCTAssertEqual(sut.sharedStatusImage.image, sut.isNotSharedImage)
  }

  func testSharedDescription_isShared_incoming() {
    let config = testMemoConfig(isShared: true, isIncoming: true)
    sut.configure(with: config)
    let expectedText = "Memo from sender"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  func testSharedDescription_isShared_outgoing_willSend() {
    let recipient = "Satoshi"
    let config = testMemoConfig(isShared: true, isSent: false, isIncoming: false, recipientName: recipient)
    sut.configure(with: config)
    let expectedText = "Will be seen by \(recipient)"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  func testSharedDescription_isShared_outgoing_didSend() {
    let recipient = "Satoshi"
    let config = testMemoConfig(isShared: true, isSent: true, isIncoming: false, recipientName: recipient)
    sut.configure(with: config)
    let expectedText = "Shared with \(recipient)"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  func testSharedDescription_isShared_outgoing_didSend_unknownRecipient() {
    let config = testMemoConfig(isShared: true, isSent: true, isIncoming: false, recipientName: nil)
    sut.configure(with: config)
    let expectedText = "Shared with the recipient"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  func testSharedDescription_notShared_willSend() {
    let config = testMemoConfig(isShared: false, isSent: false)
    sut.configure(with: config)
    let expectedText = "Will be seen by only you"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  func testSharedDescription_notShared_didSend() {
    let config = testMemoConfig(isShared: false, isSent: true)
    sut.configure(with: config)
    let expectedText = "Seen by only you"
    XCTAssertEqual(sut.sharedStatusLabel.text, expectedText)
  }

  private func testMemoConfig(memo: String = "My memo",
                              isShared: Bool = true,
                              isSent: Bool = true,
                              isIncoming: Bool = false,
                              recipientName: String? = nil) -> ConfirmPaymentMemoViewConfig {
    return ConfirmPaymentMemoViewConfig(memo: memo, isShared: isShared, isSent: isSent,
                                        isIncoming: isIncoming, recipientName: recipientName)
  }
}
