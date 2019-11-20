//
//  MerchantAttributeViewTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class MerchantAttributeViewTests: XCTestCase {
  var sut: MerchantAttributeView!

  override func setUp() {
    super.setUp()
    self.sut = MerchantAttributeView()
    self.sut.awakeFromNib()

    let viewModel = MerchantAttributeResponse(type: "", description: "Its a description", link: "https://link.link")
    sut.viewModel = viewModel
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testInvoiceCellOutletsAreConnected() {
    XCTAssertNotNil(sut.imageView, "imageView should be connected")
    XCTAssertNotNil(sut.descriptionLabel, "descriptionLabel should be connected")
    XCTAssertNotNil(sut.linkButton, "linkButton should be connected")
  }

  func testTooltipButtonContainsAction() {
    let actions = sut.linkButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(MerchantAttributeView.linkButtonWasTapped).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testLinkButtonPressedCallsDelegate() {
    let delegate = MockMerchantAttributeViewDelegate()
    sut.delegate = delegate

    sut.linkButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(delegate.attributeViewWasTouchedCalled,
                  "should tell delegate that the attribute view was tapped")
  }
}
