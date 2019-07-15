//
//  RequestPayViewModelTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class RequestPayViewModelTests: XCTestCase {
  var sut: RequestPayViewModel!

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }
  
  //TODO

  // MARK: mock converter
  struct MockCurrencyConverter: CurrencyConverterType {
    var btcValue: NSDecimalNumber {
      return .zero
    }

    let rates: ExchangeRates = [.USD: 7000, .BTC: 1]
    var fromAmount: NSDecimalNumber
    var fromCurrency: CurrencyCode
    var toCurrency: CurrencyCode

    init(fromAmount: NSDecimalNumber, fromCurrency: CurrencyCode, toCurrency: CurrencyCode) {
      self.fromAmount = fromAmount
      self.fromCurrency = fromCurrency
      self.toCurrency = toCurrency
    }

    var fromDisplayValue: String {
      return "fromDisplayValue"
    }
    var toDisplayValue: String {
      return "toDisplayValue"
    }

    func convertedAmount() -> NSDecimalNumber? {
      return nil
    }
  }
}
