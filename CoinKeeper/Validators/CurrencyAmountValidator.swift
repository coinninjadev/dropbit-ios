//
//  CurrencyAmountValidator.swift
//  DropBit
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CurrencyStringValidatorError: ValidatorTypeError {
  case isZero
  case notANumber

  var debugMessage: String {
    switch self {
    case .isZero: return "Amount cannot be zero."
    case .notANumber: return "Amount is not a number."
    }
  }

  var displayMessage: String? {
    return debugMessage
  }

}

enum CurrencyAmountValidatorError: ValidatorTypeError {
  case invitationMaximum(Money)
  case usableBalance(Money) //Should be BTC
  case notANumber(String)

  var debugMessage: String {
    switch self {
    case .invitationMaximum(let money):
      return "Amount exceeds send to contact maximum: \(money.displayString)"
    case .usableBalance(let money):
      return "Amount exceeds usable balance of \(money.displayString)"
    case .notANumber(let string):
      return "The text, \"" + string + "\" is not a number."
    }
  }

  var displayMessage: String? {
    switch self {
    case .invitationMaximum:
      return """
      For security reasons we limit invite transactions to $100.
      Once your contact has the DropBit app there are no transaction limits.
      """
    case .usableBalance(let money):
      return """
      Amount cannot exceed your usable balance of \(money.displayString).
      """
    case .notANumber:
      return debugMessage
    }
  }

}

/**
 These options correlate to the CurrencyAmountValidatorError enum cases,
 since the error cases are not Equatable for evaluating validationsToSkip.contains().
 */
struct CurrencyAmountValidationOptions: OptionSet {
  let rawValue: Int

  static let invitationMaximum = CurrencyAmountValidationOptions(rawValue: 1 << 0)
  static let usableBalance = CurrencyAmountValidationOptions(rawValue: 1 << 2)
}

/// Validating against a CurrencyConverter allows for validating either the USD or BTC values
class CurrencyAmountValidator: ValidatorType<CurrencyConverter> {

  static let invitationMax = Money(amount: NSDecimalNumber(value: 100), currency: .USD)
  static let lightningInvoiceMax = Money(amount: NSDecimalNumber(value: 50), currency: .USD)

  // Allows for validating against USD value while showing error message in BTC.
  let balancesNetPending: WalletBalances
  let validationsToSkip: CurrencyAmountValidationOptions
  let balanceType: WalletTransactionType

  init(balancesNetPending: WalletBalances,
       balanceToCheck: WalletTransactionType,
       ignoring: CurrencyAmountValidationOptions = []) {
    self.balancesNetPending = balancesNetPending
    self.balanceType = balanceToCheck
    self.validationsToSkip = ignoring
    super.init()
  }

  private var relevantBalance: NSDecimalNumber {
    switch balanceType {
    case .onChain:
      return balancesNetPending.onChain
    case .lightning:
      return balancesNetPending.lightning
    }
  }

  override func validate(value: CurrencyConverter) throws {
    let btcValue = value.btcAmount
    let usdValue = value.amount(forCurrency: .USD) ?? .zero

    switch btcValue {
    case .notANumber: throw CurrencyStringValidatorError.notANumber
    case .zero:       throw CurrencyStringValidatorError.isZero
    default:          break
    }

    let maxMoney = CurrencyAmountValidator.invitationMax

    if !validationsToSkip.contains(.invitationMaximum),
      maxMoney.amount < usdValue {
      throw CurrencyAmountValidatorError.invitationMaximum(maxMoney)
    }

    let balance = relevantBalance

    if !validationsToSkip.contains(.usableBalance), btcValue > balance {
      let spendableMoney = Money(amount: balance, currency: .BTC)
      throw CurrencyAmountValidatorError.usableBalance(spendableMoney)
    }
  }

}
