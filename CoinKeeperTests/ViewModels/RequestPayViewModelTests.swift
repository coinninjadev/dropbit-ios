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

  // MARK: primary currency value
  func testWhenAccessingPrimaryCurrencyValueAsksConverterForFromDisplayValue() {
    let mockCurrencyConverter = MockCurrencyConverter(fromAmount: 50, fromCurrency: .USD, toCurrency: .BTC)
    self.sut = RequestPayViewModel(receiveAddress: "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu", currencyConverter: mockCurrencyConverter)

    _ = self.sut.primaryCurrencyValue

    XCTAssertEqual(self.sut.primaryCurrencyValue, mockCurrencyConverter.fromDisplayValue, "primaryCurrencyValue should equal fromDisplayValue")
  }

  // MARK: secondary currency value
  func testWhenAccessingSecondaryCurrencyValueAsksConverterForToDisplayValue() {
    let mockCurrencyConverter = MockCurrencyConverter(fromAmount: 50, fromCurrency: .USD, toCurrency: .BTC)
    self.sut = RequestPayViewModel(receiveAddress: "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu", currencyConverter: mockCurrencyConverter)

    _ = self.sut.secondaryCurrencyValue

    XCTAssertEqual(self.sut.secondaryCurrencyValue, mockCurrencyConverter.attributedStringWithSymbol(forCurrency: .BTC),
                   "secondaryCurrencyValue should equal toDisplayValue")
  }

  // MARK: handling funds
  func testHasFundsInRequestWithFundsReturnsTrue() {
    let mockCurrencyConverter = MockCurrencyConverter(fromAmount: 50, fromCurrency: .USD, toCurrency: .BTC)
    self.sut = RequestPayViewModel(receiveAddress: "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu", currencyConverter: mockCurrencyConverter)

    let hasFunds = self.sut.hasFundsInRequest

    XCTAssertTrue(hasFunds, "should have funds")
  }

  func testHasFundsInRequestWithoutFundsReturnsFalse() {
    let mockCurrencyConverter = MockCurrencyConverter(fromAmount: 0, fromCurrency: .USD, toCurrency: .BTC)
    self.sut = RequestPayViewModel(receiveAddress: "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu", currencyConverter: mockCurrencyConverter)

    let hasFunds = self.sut.hasFundsInRequest

    XCTAssertFalse(hasFunds, "should not have funds")
  }

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
