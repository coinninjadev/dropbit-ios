//
//  MockPurchaseMerchantTableViewCellDelegate.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

class MockPurchaseMerchantTableViewCellDelegate: PurchaseMerchantTableViewCellDelegate {

  var attributeLinkWasTouchedCalled = false
  func attributeLinkWasTouched(with url: URL) {
    attributeLinkWasTouchedCalled = true
  }

  var actionButtonWasPressedCalled = false
  func actionButtonWasPressed(type: MerchantCallToActionStyle, url: String) {
    actionButtonWasPressedCalled = true
  }

  var tooltipButtonWasPressedCalled = false
  func tooltipButtonWasPressed(with url: URL) {
    tooltipButtonWasPressedCalled = true
  }

}
