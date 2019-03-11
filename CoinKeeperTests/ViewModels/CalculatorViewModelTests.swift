//
//  CalculatorViewModelTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class CalculatorViewModelTests: XCTestCase {
  var sut: CalculatorViewModel!

  let rates: ExchangeRates = [.BTC: 1, .USD: 7000]

  override func setUp() {
    super.setUp()
    self.sut = CalculatorViewModel(currentAmountString: "", currentCurrencyCode: .BTC, exchangeRates: rates)
  }

  func testInitializationSetsProperties() {
    XCTAssertEqual(self.sut.currentAmountRawString, "")
    XCTAssertEqual(self.sut.currentCurrencyCode, .BTC)
  }

}
