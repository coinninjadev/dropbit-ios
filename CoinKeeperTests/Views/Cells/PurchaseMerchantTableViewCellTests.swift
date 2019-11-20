//
//  PurchaseMerchantTableViewCellTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class PurchaseMerchantTableViewCellTests: XCTestCase {
  var sut: PurchaseMerchantTableViewCell!

  override func setUp() {
    super.setUp()
    self.sut = PurchaseMerchantTableViewCell.nib().instantiate(withOwner: self, options: nil).first as? PurchaseMerchantTableViewCell
    self.sut.awakeFromNib()

    let cta = MerchantCallToActionResponse(style: "device", link: "")
    let viewModel = MerchantResponse(image: "", tooltip: "https://google.com", attributes: [], cta: cta)
    sut.load(with: viewModel)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testInvoiceCellOutletsAreConnected() {
    XCTAssertNotNil(sut.logoImageView, "logoImageView should be connected")
    XCTAssertNotNil(sut.containerView, "containerView should be connected")
    XCTAssertNotNil(sut.tooltipButton, "tooltipButton should be connected")
    XCTAssertNotNil(sut.stackView, "stackView should be connected")
    XCTAssertNotNil(sut.attributeStackView, "attributeStackView should be connected")
  }

  func testTooltipButtonContainsAction() {
    let actions = sut.tooltipButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(PurchaseMerchantTableViewCell.tooltipButtonWasTouched).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testButtonTappedWithValidDataProducesResults() {
    let mockSelectionDelegate = MockPurchaseMerchantTableViewCellDelegate()
    sut.delegate = mockSelectionDelegate

    sut.actionButton.sendActions(for: .touchUpInside)
    sut.tooltipButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockSelectionDelegate.actionButtonWasPressedCalled, "should tell delegate that the action button was tapped")
    XCTAssertTrue(mockSelectionDelegate.tooltipButtonWasPressedCalled, "should tell delegate that the tooltip button was tapped")
  }
}
