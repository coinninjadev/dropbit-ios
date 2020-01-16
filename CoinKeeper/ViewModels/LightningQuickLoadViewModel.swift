//
//  LightningQuickLoadViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 11/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct LightningQuickLoadViewModel {

  let btcBalances: WalletBalances
  let fiatBalances: WalletBalances
  let fiatCurrency: CurrencyCode
  let controlConfigs: [QuickLoadControlConfig]

  ///If true, sending max should send all spendable utxos.
  ///If false, sending max should send the specific amount shown.
  let maxIsLimitedByOnChainBalance: Bool

  static var standardAmounts: [NSDecimalNumber] {
    return [5, 10, 20, 50, 100].map { NSDecimalNumber(value: $0) }
  }

  init(spendableBalances: WalletBalances, rates: ExchangeRates, fiatCurrency: CurrencyCode) throws {
    guard let minFiatAmount = LightningQuickLoadViewModel.standardAmounts.first else {
      throw DBTError.System.missingValue(key: "standardAmounts.min")
    }

    ///Run these validations separately to produce correct error message
    //check on chain balance exceeds minFiatAmount
    let minStandardAmountConverter = CurrencyConverter(rates: rates, fromAmount: minFiatAmount, currencyPair: .USD_BTC)
    let onChainBalanceValidator = LightningWalletAmountValidator(balancesNetPending: spendableBalances,
                                                                 walletType: .onChain, ignoring: [.maxWalletValue])
    do {
      try onChainBalanceValidator.validate(value: minStandardAmountConverter)
    } catch {
      //map usableBalance error to
      throw LightningWalletAmountValidatorError.reloadMinimum
    }

    //check lightning wallet has capacity for the minFiatAmount
    let minReloadValidator = LightningWalletAmountValidator(balancesNetPending: spendableBalances,
                                                            walletType: .onChain, ignoring: [.minReloadAmount])
    try minReloadValidator.validate(value: minStandardAmountConverter)

    self.btcBalances = spendableBalances
    self.fiatCurrency = fiatCurrency
    let fiatBalances = LightningQuickLoadViewModel.convertBalances(spendableBalances, toFiat: fiatCurrency, using: rates)
    self.fiatBalances = fiatBalances
    let maxAmountResults = minReloadValidator.maxLoadAmount(using: fiatBalances)
    self.controlConfigs = LightningQuickLoadViewModel.configs(withMax: maxAmountResults.amount, currency: fiatCurrency)
    self.maxIsLimitedByOnChainBalance = maxAmountResults.limitIsOnChainBalance
  }

  private static func convertBalances(_ btcBalances: WalletBalances, toFiat currency: CurrencyCode, using rates: ExchangeRates) -> WalletBalances {
    let onChainConverter = CurrencyConverter(fromBtcTo: currency, fromAmount: btcBalances.onChain, rates: rates)
    let lightningConverter = CurrencyConverter(fromBtcTo: currency, fromAmount: btcBalances.lightning, rates: rates)
    return WalletBalances(onChain: onChainConverter.fiatAmount, lightning: lightningConverter.fiatAmount)
  }

  private static func configs(withMax max: NSDecimalNumber, currency: CurrencyCode) -> [QuickLoadControlConfig] {
    let standardConfigs = standardAmounts.map { amount -> QuickLoadControlConfig in
      let money = Money(amount: amount, currency: currency)
      return QuickLoadControlConfig(isEnabled: amount <= max, amount: money)
    }
    let maxConfig = QuickLoadControlConfig(maxAmount: Money(amount: max, currency: currency))
    return standardConfigs + [maxConfig]
  }

}
