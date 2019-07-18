//
//  CurrencyConverterTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class CurrencyConverterTests: XCTestCase {
  var sut: CurrencyConverter!

  let safeRates: ExchangeRates = [.BTC: 1, .USD: 7000]

  // MARK: invalid rates
  func testBTCToUSDWithZeroRatesReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let zeroRates: ExchangeRates = [.BTC: 0, .USD: 0]

    self.sut = CurrencyConverter(rates: zeroRates, fromAmount: fromAmount, fromCurrency: .USD, toCurrency: .BTC)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a zero rate")
  }

  func testBTCToUSDWithNegativeRateReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let negativeRates: ExchangeRates = [.BTC: 1, .USD: -7000]

    self.sut = CurrencyConverter(rates: negativeRates, fromAmount: fromAmount, fromCurrency: .USD, toCurrency: .BTC)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a negative rate")
  }

  func testBTCToUSDWithNilRateReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let nilRates: ExchangeRates = [:]

    self.sut = CurrencyConverter(rates: nilRates, fromAmount: fromAmount, fromCurrency: .USD, toCurrency: .BTC)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a nil rate")
  }

  func testInvalidFromAmountReturnsNil() {
    let fromAmount = NSDecimalNumber.notANumber
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: fromAmount, fromCurrency: .USD, toCurrency: .BTC)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with an invalid from amount")
  }

  func testRoundingReturnsRoundedValue() {
    let fromAmount = NSDecimalNumber(value: 12.123456789) //9 decimal places
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: fromAmount, fromCurrency: .BTC, toCurrency: .BTC)

    // the basic initializer used above for fromAmount includes extra decimal places from the float literal
    let expectedValue = NSDecimalNumber(mantissa: 1212345679, exponent: -Int16(CurrencyCode.BTC.decimalPlaces), isNegative: false)

    XCTAssertEqual(self.sut.convertedAmount(), expectedValue, "should round to 8 digits")
  }

  // MARK: display values
  func testGettingFromDisplayValueReturnsProperResult() {
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: 50, fromCurrency: .USD, toCurrency: .BTC)
    let actualValue = self.sut.fromDisplayValue
    let expectedValue = "$50.00"

    XCTAssertEqual(actualValue, expectedValue, "should format the currency properly")
  }

  func testConvertingUSDToBTCSecondaryCurrencyValueReturnsProperBTCValue() {
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: 50, fromCurrency: .USD, toCurrency: .BTC)
    let actualValue = self.sut.toDisplayValue
    let expectedValue = "\(CurrencyCode.BTC.symbol)0.00714286"

    XCTAssertEqual(actualValue, expectedValue, "should format the btc properly")
  }

  func testConvertingBTCToUSDPrimaryCurrencyValueReturnsProperBTCValue() {
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: 1, fromCurrency: .BTC, toCurrency: .USD)
    let actualValue = self.sut.fromDisplayValue
    let expectedValue = "\(CurrencyCode.BTC.symbol)1"

    XCTAssertEqual(actualValue, expectedValue, "should format the btc properly")
  }

  func testConvertingBTCToUSDSecondaryCurrencyValueReturnsProperBTCValue() {
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: 1, fromCurrency: .BTC, toCurrency: .USD)
    let actualValue = self.sut.toDisplayValue
    let expectedValue = "$7,000.00"

    XCTAssertEqual(actualValue, expectedValue, "should format the USD properly")
  }

  // MARK: getting btcValue
  func testBtcValueWhenFromAmountIsBTCEqualsInitialValue() {
    let expectedAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.USD] ?? 0.0))
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: expectedAmount, fromCurrency: .BTC, toCurrency: .USD)
    let actualAmount = self.sut.btcValue

    XCTAssertEqual(actualAmount, expectedAmount, "btcValue should equal initial value")
  }

  func testBtcValueWhenToAmountIsBTCEqualsExpectedValue() {
    let enteredAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.USD] ?? 0.0))
    let expectedAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.BTC] ?? 0.0))
    self.sut = CurrencyConverter(rates: self.safeRates, fromAmount: enteredAmount, fromCurrency: .USD, toCurrency: .BTC)
    let actualAmount = self.sut.btcValue

    XCTAssertEqual(actualAmount, expectedAmount, "btcValue should equal expected calculated value")
  }
}
