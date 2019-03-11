//
//  PreferredCurrencyRepresentable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Objects that need to reference the user's preferred currency should conform to this protocol.
protocol PreferredCurrencyRepresentable: AnyObject {
  var preferredCurrency: CurrencyCode { get }
}

extension PreferredCurrencyRepresentable {
  var preferredCurrency: CurrencyCode {
    return .USD // Should be determined by user preferences when available
  }
}
