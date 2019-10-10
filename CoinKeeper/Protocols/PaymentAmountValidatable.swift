//
//  PaymentAmountValidatable.swift
//  DropBit
//
//  Created by Ben Winters on 6/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol PaymentAmountValidatable {

  var balanceDataSource: BalanceDataSource? { get }

}

extension PaymentAmountValidatable {

  func createCurrencyAmountValidator(ignoring: CurrencyAmountValidationOptions = [],
                                     balanceToCheck: WalletTransactionType) -> CurrencyAmountValidator {
    let balanceNetPending = balanceDataSource?.spendableBalancesNetPending() ?? .empty
    return CurrencyAmountValidator(balancesNetPending: balanceNetPending,
                                   balanceToCheck: balanceToCheck,
                                   ignoring: ignoring)
  }

}
