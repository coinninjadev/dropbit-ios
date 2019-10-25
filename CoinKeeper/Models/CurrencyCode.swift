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

  var attributedSymbol: NSAttributedString {
    return NSAttributedString(string: symbol)
  }

  func attributedIntegerSymbol(forAmount amount: NSDecimalNumber) -> NSAttributedString? {
    guard let symbol = integerSymbol(forAmount: amount.asFractionalUnits(of: self)) else { return nil}
    return NSAttributedString(string: symbol)
  }

  func integerSymbol(forAmount amount: NSDecimalNumber) -> String? {
    return integerSymbol(forAmount: amount.asFractionalUnits(of: self))
  }

  func integerSymbol(forAmount amount: Int) -> String? {
    switch self {
    case .BTC:  return amount == 1 ? " sat" : " sats"
    case .USD:  return nil
    }
  }

  var singularIntegerSymbol: String? {
    switch self {
    case .BTC:  return " sat"
    case .USD:  return nil
    }
  }

  var isFiat: Bool {
    switch self {
    case .BTC:  return false
    default:    return true
    }
  }

}
