//
//  AppCoordinator+BalanceDataSource.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import UIKit

extension AppCoordinator: BalanceDataSource {

  /// Use this when displaying the balance
  func balanceNetPending() -> NSDecimalNumber {
    guard let wmgr = walletManager else { return .zero }
    let context = persistenceManager.createBackgroundContext()
    var balance = 0
    context.performAndWait {
      balance = wmgr.balanceNetPending(in: context)
    }
    return NSDecimalNumber(integerAmount: balance, currency: .BTC)
  }

  /// isSpendable relies on having at least 1 confirmation
  func spendableBalanceNetPending() -> NSDecimalNumber {
    guard let wmgr = walletManager else { return .zero }
    let context = persistenceManager.createBackgroundContext()
    var balance = 0
    context.performAndWait {
      balance = wmgr.spendableBalanceNetPending(in: context)
    }
    return NSDecimalNumber(integerAmount: balance, currency: .BTC)
  }

}
