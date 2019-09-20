//
//  LightningInvoiceAmountValidator.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum LightningWalletAmountValidatorError: ValidatorTypeError {
  case walletMaximum
  case reloadMinimum //Should be BTC
  case invalidAmount

  var debugMessage: String {
    switch self {
    case .invalidAmount:
      return "There was an unexpected error, please re-sync your wallet in settings"
    case .walletMaximum:
      return """
      DropBit only allows you to load a maximum of
      \(LightningWalletAmountValidator.maxWalletValue.currency.symbol)
      \(LightningWalletAmountValidator.maxWalletValue.amount)
      to your lightning wallet
      """.removingMultilineLineBreaks()
    case .reloadMinimum:
      return """
      DropBit requires you to load at least
      \(LightningWalletAmountValidator.minReloadAmount.currency.symbol)
      \(LightningWalletAmountValidator.minReloadAmount.amount) to your lightning wallet
      """.removingMultilineLineBreaks()
    }
  }

  var displayMessage: String? {
    switch self {
    case .invalidAmount:
      return "Unable to convert amount to fiat, stopping"
    case .walletMaximum:
      return "Unable to load Lightning wallet, above maximum"
    case .reloadMinimum:
      return "Funds amount too low for reload"
    }
  }
}

class LightningWalletAmountValidator: ValidatorType<CurrencyConverter> {

  static let maxWalletValue = Money(amount: NSDecimalNumber(value: 500), currency: .USD)
  static let minReloadAmount = Money(amount: NSDecimalNumber(value: 5), currency: .USD)

  let balancesNetPending: WalletBalances

  init(balancesNetPending: WalletBalances) {
    self.balancesNetPending = balancesNetPending
    super.init()
  }

  override func validate(value: CurrencyConverter) throws {
    guard let usdAmount = value.amount(forCurrency: .USD) else {
      throw LightningWalletAmountValidatorError.invalidAmount
    }

    let btcValue = value.btcAmount

    switch btcValue {
    case .notANumber: throw CurrencyStringValidatorError.notANumber
    case .zero:       throw CurrencyStringValidatorError.isZero
    default:          break
    }

    if btcValue > balancesNetPending.onChain {
      let spendableMoney = Money(amount: balancesNetPending.onChain, currency: .BTC)
      throw CurrencyAmountValidatorError.usableBalance(spendableMoney)
    }

    if usdAmount < LightningWalletAmountValidator.minReloadAmount.amount {
      throw LightningWalletAmountValidatorError.reloadMinimum
    }

    if usdAmount > LightningWalletAmountValidator.maxWalletValue.amount ||
      btcValue + balancesNetPending.lightning > LightningWalletAmountValidator.maxWalletValue.amount {
      throw LightningWalletAmountValidatorError.walletMaximum
    }

  }
}
