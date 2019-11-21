//
//  LightningQuickLoadViewModelTests.swift
//  DropBit
//
//  Created by Ben Winters on 11/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import XCTest
@testable import DropBit

class LightningQuickLoadViewModelTests: XCTestCase {

  var sut: LightningQuickLoadViewModel!

  override func tearDown() {
    super.tearDown()
    sut = nil
  }

  func testLowOnChainBalanceThrowsError() {
    let oneSat = NSDecimalNumber(integerAmount: 1, currency: .BTC)
    let balances = WalletBalances(onChain: oneSat, lightning: .zero)
    let expectedError = LightningWalletAmountValidatorError.reloadMinimum
    let rates = CurrencyConverter.sampleRates
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, currency: .USD)
      XCTFail("Should throw error")
    } catch let error as LightningWalletAmountValidatorError {
      XCTAssertEqual(error, expectedError)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testHighLightningBalanceThrowsError() {
    let balances = WalletBalances(onChain: .one, lightning: .one)
    let expectedError = LightningWalletAmountValidatorError.walletMaximum
    let rates = CurrencyConverter.sampleRates
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, currency: .USD)
      XCTFail("Should throw error")
    } catch let error as LightningWalletAmountValidatorError {
      XCTAssertEqual(error, expectedError)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testModerateOnChainBalanceEqualsMaxAmount() {
    let expectedMaxFiatAmount = NSDecimalNumber(integerAmount: 2050, currency: .USD)
    let rates = CurrencyConverter.sampleRates
    let balanceConverter = CurrencyConverter(rates: rates, fromAmount: expectedMaxFiatAmount, currencyPair: .USD_BTC)
    let balances = WalletBalances(onChain: balanceConverter.btcAmount, lightning: .zero)
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, currency: .USD)
      XCTAssertEqual(sut.controlConfigs.last!.amount.amount, expectedMaxFiatAmount)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testHighOnChainBalanceIsLimitedByMaxLightningBalance() {

  }

}
