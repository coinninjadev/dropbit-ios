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

  func converter(fromUSDAmount usdAmount: NSDecimalNumber, withRates rates: ExchangeRates) -> CurrencyConverter {
    let currencyPair = CurrencyPair(primary: .USD, secondary: .BTC, fiat: .USD)
    return CurrencyConverter(rates: rates, fromAmount: usdAmount, currencyPair: currencyPair)
  }

  // MARK: invalid rates
  func testBTCToUSDWithZeroRatesReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let zeroRates: ExchangeRates = [.BTC: 0, .USD: 0]

    self.sut = converter(fromUSDAmount: fromAmount, withRates: zeroRates)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a zero rate")
  }

  func testBTCToUSDWithNegativeRateReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let negativeRates: ExchangeRates = [.BTC: 1, .USD: -7000]

    self.sut = converter(fromUSDAmount: fromAmount, withRates: negativeRates)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a negative rate")
  }

  func testBTCToUSDWithNilRateReturnsNil() {
    let fromAmount: NSDecimalNumber = 15
    let nilRates: ExchangeRates = [:]

    self.sut = converter(fromUSDAmount: fromAmount, withRates: nilRates)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with a nil rate")
  }

  func testInvalidFromAmountReturnsNil() {
    let fromAmount = NSDecimalNumber.notANumber
    self.sut = converter(fromUSDAmount: fromAmount, withRates: safeRates)

    XCTAssertNil(self.sut.convertedAmount(), "converted amount should be nil with an invalid from amount")
  }

  // MARK: display values
  func testGettingFromDisplayValueReturnsProperResult() {
    self.sut = converter(fromUSDAmount: 50, withRates: safeRates)
    let actualValue = self.sut.fromDisplayValue
    let expectedValue = "$50.00"

    XCTAssertEqual(actualValue, expectedValue, "should format the currency properly")
  }

  func testConvertingUSDToBTCSecondaryCurrencyValueReturnsProperBTCValue() {
    self.sut = converter(fromUSDAmount: 50, withRates: safeRates)
    let actualValue = self.sut.toDisplayValue
    let expectedValue = "\(CurrencyCode.BTC.symbol)0.00714286"

    XCTAssertEqual(actualValue, expectedValue, "should format the btc properly")
  }

  func testConvertingBTCToUSDPrimaryCurrencyValueReturnsProperBTCValue() {
    self.sut = CurrencyConverter(fromBtcTo: .USD, fromAmount: 1, rates: safeRates)
    let actualValue = self.sut.fromDisplayValue
    let expectedValue = "\(CurrencyCode.BTC.symbol)1"

    XCTAssertEqual(actualValue, expectedValue, "should format the btc properly")
  }

  func testConvertingBTCToUSDSecondaryCurrencyValueReturnsProperBTCValue() {
    self.sut = CurrencyConverter(fromBtcTo: .USD, fromAmount: 1, rates: safeRates)
    let actualValue = self.sut.toDisplayValue
    let expectedValue = "$7,000.00"

    XCTAssertEqual(actualValue, expectedValue, "should format the USD properly")
  }

  // MARK: getting btcValue
  func testBtcValueWhenFromAmountIsBTCEqualsInitialValue() {
    let expectedAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.USD] ?? 0.0))
    self.sut = CurrencyConverter(fromBtcTo: .USD, fromAmount: expectedAmount, rates: safeRates)
    let actualAmount = self.sut.btcAmount

    XCTAssertEqual(actualAmount, expectedAmount, "btcValue should equal initial value")
  }

  func testBtcValueWhenToAmountIsBTCEqualsExpectedValue() {
    let enteredAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.USD] ?? 0.0))
    let expectedAmount = NSDecimalNumber(decimal: Decimal(self.safeRates[.BTC] ?? 0.0))
    self.sut = converter(fromUSDAmount: enteredAmount, withRates: safeRates)
    let actualAmount = self.sut.btcAmount

    XCTAssertEqual(actualAmount, expectedAmount, "btcValue should equal expected calculated value")
  }
}
