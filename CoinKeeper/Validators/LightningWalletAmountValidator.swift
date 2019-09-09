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

  var debugMessage: String {
    switch self {
    case .walletMaximum:
      return "DropBit only allows you to load a maximum of $500 to your lightning wallet"
    case .reloadMinimum:
      return "DropBit requires you to load at least $5.00 to your lightning wallet"
    }
  }

  var displayMessage: String? {
    switch self {
    case .walletMaximum:
      return "Unable to load lightning wallet, above maximum"
    case .reloadMinimum:
      return "Funds amount too low for reload"
    }
  }
}

class LightningWalletAmountValidator: ValidatorType<CurrencyConverter> {

  static let lightningReloadThreshholdMax = Money(amount: NSDecimalNumber(value: 500), currency: .USD)
  static let lightningReloadAmountMinimum = Money(amount: NSDecimalNumber(value: 5), currency: .USD)

  let balanceNetPending: WalletBalances

  init(balanceNetPending: WalletBalances) {
    self.balanceNetPending = balanceNetPending
    super.init()
  }

  override func validate(value: CurrencyConverter) throws {
    let btcValue = value.btcAmount

    switch btcValue {
    case .notANumber: throw CurrencyStringValidatorError.notANumber
    case .zero:       throw CurrencyStringValidatorError.isZero
    default:          break
    }

    if btcValue > balanceNetPending.lightning {
      let spendableMoney = Money(amount: balanceNetPending.lightning, currency: .BTC)
      throw CurrencyAmountValidatorError.usableBalance(spendableMoney)
    }

    if btcValue < LightningWalletAmountValidator.lightningReloadAmountMinimum.amount {
      throw LightningWalletAmountValidatorError.reloadMinimum
    }

    if btcValue > LightningWalletAmountValidator.lightningReloadThreshholdMax.amount ||
      btcValue + balanceNetPending.lightning > LightningWalletAmountValidator.lightningReloadThreshholdMax.amount {
      throw LightningWalletAmountValidatorError.walletMaximum
    }

  }
}
