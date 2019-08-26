//
//  CurrencyFormatterTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class CurrencyFormatterTests: XCTestCase {

    func testFiatFormatterWithSymbol() {
      let formatter = FiatFormatter(currency: .USD, withSymbol: true)
      let amount = NSDecimalNumber(value: 50)
      let expectedValue = "$50.00"

      XCTAssertEqual(formatter.string(fromDecimal: amount), expectedValue)
    }

    func testBitcoinFormatterWithSymbol() {
      let formatter = BitcoinFormatter(symbolType: .string)
      let amount = NSDecimalNumber(integerAmount: 714286, currency: .BTC)
      let expectedValue = "\(CurrencyCode.BTC.symbol)0.00714286"

      XCTAssertEqual(formatter.string(fromDecimal: amount), expectedValue)
    }

  //  func testConvertingBTCToUSDPrimaryCurrencyValueReturnsProperBTCValue() {
  //    self.sut = CurrencyConverter(fromBtcTo: .USD, fromAmount: 1, rates: safeRates)
  //    let actualValue = self.sut.fromDisplayValue
  //    let expectedValue = "\(CurrencyCode.BTC.symbol)1"
  //
  //    XCTAssertEqual(actualValue, expectedValue, "should format the btc properly")
  //  }
  //
  //  func testConvertingBTCToUSDSecondaryCurrencyValueReturnsProperBTCValue() {
  //    self.sut = CurrencyConverter(fromBtcTo: .USD, fromAmount: 1, rates: safeRates)
  //    let actualValue = self.sut.toDisplayValue
  //    let expectedValue = "$7,000.00"
  //
  //    XCTAssertEqual(actualValue, expectedValue, "should format the USD properly")
  //  }

}
