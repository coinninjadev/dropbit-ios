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

  func createCurrencyAmountValidator(ignoring: CurrencyAmountValidationOptions = []) -> CurrencyAmountValidator {
    let balanceNetPending = balanceDataSource?.spendableBalanceNetPending()
    return CurrencyAmountValidator(balanceNetPending: balanceNetPending, ignoring: ignoring)
  }

}
