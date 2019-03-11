//
//  CurrencyCode.swift
//  CoinKeeper
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

  private var image: UIImage? {
    switch self {
    case .USD: return nil
    case .BTC: return UIImage(named: "bitcoinLogo")
    }
  }

  private static var defaultSize: Int {
    return 20
  }

  func attributedStringSymbol(ofSize size: Int = defaultSize) -> NSAttributedString? {
    switch self {
    case .USD: return nil
    case .BTC:
      let textAttribute = NSTextAttachment()
      textAttribute.image = image
      textAttribute.bounds = CGRect(x: -3, y: (-size / (CurrencyCode.defaultSize / 4)),
                                    width: size, height: size)

      return NSAttributedString(attachment: textAttribute)
    }
  }

  var usesCustomSymbol: Bool {
    switch self {
    case .BTC:	return true
    case .USD:	return false
    }
  }

  var shouldRoundTrailingZeroes: Bool {
    switch self {
    case .BTC:	return true
    case .USD:	return false
    }
  }

}
