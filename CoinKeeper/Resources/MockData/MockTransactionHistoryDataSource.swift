//
//  MockTransactionHistoryDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class MockTransactionHistoryDataSource: TransactionHistoryDataSourceType {

  let walletTransactionType: WalletTransactionType
  weak var delegate: TransactionHistoryDataSourceDelegate?

  fileprivate var items: [TransactionDetailCellDisplayable]

  init(walletTxType: WalletTransactionType) {
    self.walletTransactionType = walletTxType
    let onChainGenerator = MockDetailDataGenerator(walletTxType: walletTxType)
    let onChainDropBits = onChainGenerator.generatePhoneAndTwitterDropBitItems()
    self.items = onChainDropBits
  }

  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable {
    return items[indexPath.row]
  }

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable? {
    return items[indexPath.row]
  }

  func numberOfSections() -> Int {
    return 1
  }

  func numberOfItems(inSection section: Int) -> Int {
    return items.count
  }

}

class MockTransactionHistoryOnChainDataSource: MockTransactionHistoryDataSource {

  init() {
    super.init(walletTxType: .onChain)
    // will append onChain-specific items
  }

}

class MockTransactionHistoryLightningDataSource: MockTransactionHistoryDataSource {

  init() {
    super.init(walletTxType: .lightning)
    // will append lightning-specific items
  }

}
