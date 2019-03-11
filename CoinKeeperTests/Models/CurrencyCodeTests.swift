//
//  CurrencyCodeTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class CurrencyCodeTests: XCTestCase {
  var sut: CurrencyCode!

  let usdSymbol = "$"
  let btcSymbol = "\u{20BF} "

  // MARK: USD
  func testUSDHasSymbolAndDecimalPlaces() {
    self.sut = .USD

    XCTAssertEqual(self.sut.symbol, self.usdSymbol)
    XCTAssertEqual(self.sut.decimalPlaces, 2, "usd should have 2 decimal places")
  }

  // MARK: BTC
  func testBTCHasSymbolAndDecimalPlaces() {
    self.sut = .BTC

    XCTAssertEqual(self.sut.symbol, self.btcSymbol)
    XCTAssertEqual(self.sut.decimalPlaces, 8, "btc should have 8 decimal places")
  }
}
