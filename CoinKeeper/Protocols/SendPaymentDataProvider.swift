//
//  SendPaymentDataProvider.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol SendPaymentDataProvider {
  var address: String? { get }
  var btcAmount: NSDecimalNumber? { get }
  var primaryCurrency: CurrencyCode { get }
}

extension SendPaymentDataProvider {

  /// Pass in the current rates from the ExchangeRateManager
  func amountLabels(withRates rates: ExchangeRates, withSymbols: Bool) -> (primary: String?, secondary: NSAttributedString?) {
    let fromAmount = btcAmount ?? .zero
    let converter = CurrencyConverter(rates: rates, fromAmount: fromAmount, fromCurrency: .BTC, toCurrency: .USD)

    var primaryLabel = converter.amountStringWithSymbol(forCurrency: primaryCurrency)

    let secondaryCurrency = converter.otherCurrency(forCurrency: primaryCurrency)
    var secondaryLabel = secondaryCurrency.flatMap({ converter.attributedStringWithSymbol(forCurrency: $0) })

    if !withSymbols {
      primaryLabel = String(describing: converter.amount(forCurrency: primaryCurrency) ?? 0)
      secondaryLabel = secondaryCurrency.flatMap({ NSAttributedString(string: String(describing: converter.amount(forCurrency: $0) ?? 0)) })
    }

    return (primaryLabel, secondaryLabel)
  }
}
