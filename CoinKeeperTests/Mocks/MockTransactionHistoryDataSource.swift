//
//  MockTransactionHistoryDataSource.swift
//  CoinKeeper
//
//  Created by Ben Winters on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class MockTransactionHistoryOnChainDataSource: TransactionHistoryDataSourceType {

  private let items: [TransactionSummaryCellDisplayable]

  let walletTransactionType: WalletTransactionType = .onChain

  weak var changeDelegate: TransactionHistoryDataSourceChangeDelegate?

  init() {
    let gen = MockOnChainDataGenerator()
    self.items = [
      gen.mayUtilities,
      gen.lightningWithdraw,
      gen.coffee,
      gen.drinksAndFood,
      gen.loadLightning,
      gen.genericIncoming,
      gen.canceledPhoneInvite
    ]
  }

  func summaryCellDisplayableItem(at indexPath: IndexPath, rates: ExchangeRates, currencies: CurrencyPair) -> TransactionSummaryCellDisplayable {
    return items[indexPath.row]
  }

  func numberOfSections() -> Int {
    return 1
  }

  func numberOfItems(inSection section: Int) -> Int {
    return items.count
  }

}
