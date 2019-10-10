//
//  ConfirmViewTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class ConfirmViewTests: XCTestCase {

  var sut: ConfirmView!
  let frame = CGRect(x: 0, y: 0, width: 252, height: 48)

  override func setUp() {
    super.setUp()
    sut = ConfirmView(frame: frame)
    _ = self.sut.xibSetup()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.confirmButton, "confirmButton should be connected")
    XCTAssertNotNil(sut.tapAndHoldLabel, "tapAndHoldLabel should be connected")
  }

  func testConfirmButtonContainsActions() {
    let touchUpInsideActions = sut.confirmButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let touchUpOutsideActions = sut.confirmButton.actions(forTarget: sut, forControlEvent: .touchUpOutside) ?? []
    let touchDownActions = sut.confirmButton.actions(forTarget: sut, forControlEvent: .touchDown) ?? []

    let heldSelector = #selector(ConfirmView.confirmButtonWasHeld).description
    let releasedSelector = #selector(ConfirmView.confirmButtonWasReleased).description

    XCTAssertTrue(touchUpInsideActions.contains(releasedSelector), "confirmButton touch up inside should contain released selector")
    XCTAssertTrue(touchUpOutsideActions.contains(releasedSelector), "confirmButton touch up outside should contain released selector")
    XCTAssertTrue(touchDownActions.contains(heldSelector), "confirmButton held should contain released selector")
  }
}
