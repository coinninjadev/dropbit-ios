//
//  MockCalculatorViewModel.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockCalculatorViewModel: CalculatorViewModelProviding {

  var exchangeRates: ExchangeRates = [:]

  var currencyConverter: CurrencyConverter {
    let toCurrency: CurrencyCode = (currentCurrencyCode == .BTC) ? .USD : .BTC
    return CurrencyConverter(rates: exchangeRates, fromAmount: 1, fromCurrency: currentCurrencyCode, toCurrency: toCurrency)
  }

  var currentAmountRawString: String

  var currentCurrencyCode: CurrencyCode

  init(currentAmountString: String, currentCurrencyCode: CurrencyCode) {
    self.currentAmountRawString = currentAmountString
    self.currentCurrencyCode = currentCurrencyCode
  }

  var bitcoinAmount: NSDecimalNumber {
    return 0
  }

  func apply(_ change: CalculatorViewModelChange) {
    switch change {
    case .append(let digit):
      currentAmountRawString += digit
    case .decimal:
      currentAmountRawString += "."
    case .backspace:
      if !currentAmountRawString.isEmpty {
        currentAmountRawString.removeLast()
      }

    case .currency(let code):
      currentCurrencyCode = code

    case .exchangeRates(let rates):
      self.exchangeRates = rates
    case .reset:
      currentAmountRawString = ""
    }
  }

  var labels: CalculatorViewLabels {
    return CalculatorViewLabels(leftCurrencyButton: "left",
                                rightCurrencyButton: "right",
                                currentAmount: NSAttributedString(string: "current"),
                                convertedAmount: NSAttributedString(string: "converted"))
  }

  var currencyToggleConfig: CalculatorCurrencyToggleConfig {
    return CalculatorCurrencyToggleConfig(leftButtonTitle: "left",
                                          rightButtonTitle: "right",
                                          selectedSegment: .left)
  }

}
