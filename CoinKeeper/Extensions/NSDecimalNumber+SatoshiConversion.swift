//
//  Int+SatoshiConversion.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NSDecimalNumber {

  private var multiplier: NSDecimalNumber {
    return NSDecimalNumber(value: 100000000.0)
  }

  func convertBitcoinToSatoshis() -> Int {
    guard self.isNumber else { return 0 }
    return self.multiplying(by: multiplier).intValue
  }

  func convertUsdToCents() -> Int {
    guard self.isNumber else { return 0 }
    return self.multiplying(by: 100.0).intValue
  }
}
