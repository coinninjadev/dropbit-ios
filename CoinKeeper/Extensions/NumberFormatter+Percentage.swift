//
//  NumberFormatter+Percentage.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/21/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NumberFormatter {

  static var percentageFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = true
    return formatter
  }()
}
