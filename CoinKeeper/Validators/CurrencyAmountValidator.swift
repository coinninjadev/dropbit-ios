//
//  CurrencyAmountValidator.swift
//  DropBit
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

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

  // Allows for validating against USD value while showing error message in BTC.
  let balanceNetPending: WalletBalances?
  let validationsToSkip: CurrencyAmountValidationOptions

  init(balanceNetPending: WalletBalances?, ignoring: CurrencyAmountValidationOptions = []) {
    self.balanceNetPending = balanceNetPending
    self.validationsToSkip = ignoring
    super.init()
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

    if !validationsToSkip.contains(.usableBalance),
      let balance = balanceNetPending?.onChain, //TODO: Add check for lightning funds
      btcValue > balance {
      let spendableMoney = Money(amount: balance, currency: .BTC)
      throw CurrencyAmountValidatorError.usableBalance(spendableMoney)
    }
  }

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

}
