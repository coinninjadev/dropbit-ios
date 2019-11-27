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
      sut = try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, fiatCurrency: .USD)
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
      sut = try LightningQuickLoadViewModel(spendableBalances: balances, rates: rates, fiatCurrency: .USD)
      XCTFail("Should throw error")
    } catch let error as LightningWalletAmountValidatorError {
      XCTAssertEqual(error, expectedError)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testModerateOnChainBalanceEqualsMaxAmount() {
    let expectedMaxFiatAmount = NSDecimalNumber(integerAmount: 20_50, currency: .USD)
    let rates = CurrencyConverter.sampleRates
    let balanceConverter = CurrencyConverter(rates: rates, fromAmount: expectedMaxFiatAmount, currencyPair: .USD_BTC)
    let btcBalances = WalletBalances(onChain: balanceConverter.btcAmount, lightning: .zero)
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: btcBalances, rates: rates, fiatCurrency: .USD)
      XCTAssertEqual(sut.controlConfigs.last!.amount.amount, expectedMaxFiatAmount)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testHighOnChainBalanceIsLimitedByMaxLightningBalance() {
    let expectedMaxFiatAmount = NSDecimalNumber(integerAmount: 20_00, currency: .USD)
    let lightningFiatBalance = NSDecimalNumber(integerAmount: 180_00, currency: .USD)
    let rates = CurrencyConverter.sampleRates
    let balanceConverter = CurrencyConverter(rates: rates, fromAmount: lightningFiatBalance, currencyPair: .USD_BTC)
    let btcBalances = WalletBalances(onChain: .one, lightning: balanceConverter.btcAmount)
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: btcBalances, rates: rates, fiatCurrency: .USD)
      XCTAssertEqual(sut.controlConfigs.last!.amount.amount, expectedMaxFiatAmount)
    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

  func testHigherStandardAmountsAreDisabledByMaxAmount() {
    let onChainFiatBalance = NSDecimalNumber(integerAmount: 45_00, currency: .USD)
    let rates = CurrencyConverter.sampleRates
    let balanceConverter = CurrencyConverter(rates: rates, fromAmount: onChainFiatBalance, currencyPair: .USD_BTC)
    let btcBalances = WalletBalances(onChain: balanceConverter.btcAmount, lightning: .zero)
    do {
      sut = try LightningQuickLoadViewModel(spendableBalances: btcBalances, rates: rates, fiatCurrency: .USD)
      let expectedEnabledValues: [NSDecimalNumber] = [5, 10, 20, 45].map { NSDecimalNumber(value: $0) }
      let actualEnabledValues = sut.controlConfigs.filter { $0.isEnabled }.map { $0.amount.amount }
      XCTAssertEqual(expectedEnabledValues, actualEnabledValues)

    } catch {
      XCTFail("Threw unexpected error: \(error.localizedDescription)")
    }
  }

}
