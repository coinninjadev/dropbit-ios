//
//  MockCurrencySwappableEditAmountViewDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 7/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockCurrencySwappableEditAmountViewDelegate: CurrencySwappableEditAmountViewDelegate {

  var swapViewDidSwapValue = false
  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView) {
    swapViewDidSwapValue = true
  }

}
