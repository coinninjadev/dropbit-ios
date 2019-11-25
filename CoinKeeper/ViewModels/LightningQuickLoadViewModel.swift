//
//  LightningQuickLoadViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 11/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct LightningQuickLoadViewModel {

  let balances: WalletBalances
  let currency: CurrencyCode
  let controlConfigs: [QuickLoadControlConfig]

  ///If true, sending max should send all spendable utxos.
  ///If false, sending max should send the specific amount shown.
  let maxIsLimitedByOnChainBalance: Bool

  static var standardAmounts: [NSDecimalNumber] {
    return [5, 10, 20, 50, 100].map { NSDecimalNumber(value: $0) }
  }

  init(spendableBalances: WalletBalances, rates: ExchangeRates, currency: CurrencyCode) throws {
    guard let minFiatAmount = LightningQuickLoadViewModel.standardAmounts.first else {
      throw CKSystemError.missingValue(key: "standardAmounts.min")
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

    self.balances = spendableBalances
    self.currency = currency

    let maxAmountResults = minReloadValidator.maxLoadAmount(using: rates)
    self.controlConfigs = LightningQuickLoadViewModel.configs(withMax: maxAmountResults.amount, currency: currency)
    self.maxIsLimitedByOnChainBalance = maxAmountResults.limitIsOnChainBalance
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
