//
//  CurrencyCode.swift
//  DropBit
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

/// The raw value should match the ISO 4217 currency code to allow for initialization from the string.
enum CurrencyCode: String {

  case BTC
  case USD

  init?(code: String) {
    if code == "XBT" { //Commonly used code for Bitcoin
      self.init(rawValue: "BTC")
    } else {
      self.init(rawValue: code)
    }
  }

  var decimalPlaces: Int {
    switch self {
    case .USD:	return 2
    case .BTC:	return 8
    }
  }

  var symbol: String {
    switch self {
    case .BTC:	return "\u{20BF} "
    case .USD:	return "$"
    }
  }

  func integerSymbol(forAmount amount: Int) -> String? {
    switch self {
    case .BTC:  return amount == 1 ? " sat" : " sats"
    case .USD:  return nil
    }
  }

  func integerSymbol(forAmount amount: NSDecimalNumber) -> String? {
    let fractionalUnits = amount.asFractionalUnits(of: self)
    return integerSymbol(forAmount: fractionalUnits)
  }

  var isFiat: Bool {
    switch self {
    case .BTC:  return false
    default:    return true
    }
  }

}
