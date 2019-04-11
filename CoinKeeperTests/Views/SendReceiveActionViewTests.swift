//
//  SendReceiveActionViewTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SendReceiveActionViewTests: XCTestCase {

  var sut: SendReceiveActionView!
  let frame = CGRect(x: 0, y: 0, width: 252, height: 48)

  override func setUp() {
    super.setUp()
    sut = SendReceiveActionView(frame: frame)
    _ = self.sut.xibSetup()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.receiveButton, "receiveButton should be connected")
    XCTAssertNotNil(sut.scanButton, "scanButton should be connected")
    XCTAssertNotNil(sut.sendButton, "sendButton should be connected")
  }

  // MARK: outlets contain actions
  func testReceiveButtonContainsAction() {
    let actions = sut.receiveButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let actionDescription = #selector(SendReceiveActionView.receiveTapped(_:)).description
    XCTAssertTrue(actions.contains(actionDescription))
  }

  func testScanButtonContainsAction() {
    let actions = sut.scanButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let actionDescription = #selector(SendReceiveActionView.scanTapped(_:)).description
    XCTAssertTrue(actions.contains(actionDescription))
  }

  func testSendButtonContainsAction() {
    let actions = sut.sendButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let actionDescription = #selector(SendReceiveActionView.sendTapped(_:)).description
    XCTAssertTrue(actions.contains(actionDescription))
  }

  // MARK: actions produce results
  func testReceiveButtonTellsDelegate() {
    let mockDelegate = MockActionDelegate()
    sut.actionDelegate = mockDelegate

    sut.receiveButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.didSelectReceive)
  }

  func testScanButtonTellsDelegate() {
    let mockDelegate = MockActionDelegate()
    sut.actionDelegate = mockDelegate

    sut.scanButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.didSelectScan)
  }

  func testSendButtonTellsDelegate() {
    let mockDelegate = MockActionDelegate()
    sut.actionDelegate = mockDelegate

    sut.sendButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.didSelectSend)
  }

  // MARK: private
  fileprivate class MockActionDelegate: SendReceiveActionViewDelegate {
    var didSelectReceive = false
    func actionViewDidSelectReceive(_ view: UIView) {
      didSelectReceive = true
    }

    var didSelectScan = false
    func actionViewDidSelectScan(_ view: UIView) {
      didSelectScan = true
    }

    var didSelectSend = false
    func actionViewDidSelectSend(_ view: UIView) {
      didSelectSend = true
    }
  }
}
