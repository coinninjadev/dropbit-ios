//
//  NSDecimalNumber+NilInitializer.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NSDecimalNumber {

  convenience init?(fromString: String, locale: Locale = .current) {
    self.init(string: fromString, locale: locale)

    switch self {
    case .notANumber:
      return nil
    default:
      break
    }
  }

  var isNumber: Bool {
    return self != .notANumber
  }

  var isNotZero: Bool {
    return self != .zero
  }

  var isPositiveNumber: Bool {
    return (self.isNumber && self > .zero)
  }

}
