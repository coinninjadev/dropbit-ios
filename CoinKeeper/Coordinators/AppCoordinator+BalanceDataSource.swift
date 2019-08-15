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
  func balanceNetPending() -> WalletBalances {
    guard let wmgr = walletManager else { return (onChain: .zero, lightning: .zero)}
    let context = persistenceManager.createBackgroundContext()
    var balance = (onChain: 0, lightning: 0)
    context.performAndWait {
      balance = wmgr.balanceNetPending(in: context)
    }
    return (onChain: NSDecimalNumber(integerAmount: balance.onChain, currency: .BTC),
            lightning: NSDecimalNumber(integerAmount: balance.lightning, currency: .BTC))
  }

  /// isSpendable relies on having at least 1 confirmation
  func spendableBalanceNetPending() -> WalletBalances {
    guard let wmgr = walletManager else { return (onChain: .zero, lightning: .zero)}
    let context = persistenceManager.createBackgroundContext()
    var balance = (onChain: 0, lightning: 0)
    context.performAndWait {
      balance = wmgr.spendableBalance(in: context)
    }
    return (onChain: NSDecimalNumber(integerAmount: balance.onChain, currency: .BTC),
            lightning: NSDecimalNumber(integerAmount: balance.lightning, currency: .BTC))
  }

}
