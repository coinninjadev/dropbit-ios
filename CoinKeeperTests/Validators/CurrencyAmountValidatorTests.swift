//
//  CurrencyAmountValidatorTests.swift
//  DropBitTests
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class CurrencyAmountValidatorTests: XCTestCase {
  var sut: OnChainAmountValidator!

  let rates: ExchangeRates = [.BTC: 1, .USD: 8000]
  let maxMoney = Money(amount: NSDecimalNumber(decimal: 100.0), currency: .USD)

  override func setUp() {
    super.setUp()
    self.sut = OnChainAmountValidator(balanceNetPending: nil, ignoring: [.usableBalance])
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testValueGreaterThan100USDReturnsError() {
    let money = Money(amount: NSDecimalNumber(decimal: 1000.0), currency: .USD)
    let pair = CurrencyPair(primary: money.currency, fiat: money.currency)
    let converter = CurrencyConverter(rates: rates, fromAmount: money.amount, currencyPair: pair)

    do {
      try self.sut.validate(value: converter)
    } catch let error as CurrencyAmountValidatorError {
      guard case let .invitationMaximum(errorMoney) = error else {
        XCTFail("should throw .invitationMaximum")
        return
      }
      XCTAssertEqual(errorMoney, maxMoney, "associated money object should be maxMoney")
    } catch {
      XCTFail("should throw error of type CurrencyAmountValidatorError")
    }
  }

  func testValueLessThan100USDShouldNotThrow() {
    let pair = CurrencyPair(primary: maxMoney.currency, fiat: maxMoney.currency)
    let converter = CurrencyConverter(rates: rates, fromAmount: maxMoney.amount, currencyPair: pair)

    XCTAssertNoThrow(try self.sut.validate(value: converter),
                     "value less than 100 USD should not throw")
  }

}
