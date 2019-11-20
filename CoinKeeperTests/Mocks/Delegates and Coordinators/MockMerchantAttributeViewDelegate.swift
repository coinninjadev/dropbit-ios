//
//  MockMerchantAttributeViewDelegate.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

class MockMerchantAttributeViewDelegate: MerchantAttributeViewDelegate {

  var attributeViewWasTouchedCalled = false
  func attributeViewWasTouched(with url: URL) {
    attributeViewWasTouchedCalled = true
  }

}
