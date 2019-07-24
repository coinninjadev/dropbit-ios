//
//  CKNumberFormatter.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct CKNumberFormatter {

  static let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = true
    formatter.numberStyle = .currency
    return formatter
  }()
}
