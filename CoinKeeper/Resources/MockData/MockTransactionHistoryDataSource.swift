//
//  MockTransactionHistoryDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

typealias TransactionCellDisplayable = TransactionSummaryCellDisplayable & TransactionDetailCellDisplayable
class MockTransactionHistoryDataSource: TransactionHistoryDataSourceType {

  let walletTransactionType: WalletTransactionType
  weak var delegate: TransactionHistoryDataSourceDelegate?

  fileprivate var items: [TransactionCellDisplayable]
  fileprivate let generator: MockDetailDataGenerator

  init(walletTxType: WalletTransactionType) {
    self.walletTransactionType = walletTxType
    generator = MockDetailDataGenerator(walletTxType: walletTxType)
    let dropBitItems = generator.generatePhoneAndTwitterDropBitItems(categories: MockDataDropBitCategory.allCases)
    self.items = dropBitItems
  }

  func indexPathsToAnimate() -> [IndexPath] {
    return []
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
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable {
    return items[indexPath.row]
  }

  func detailPopoverDisplayableItem(at indexPath: IndexPath,
                                    rates: ExchangeRates,
                                    currencies: CurrencyPair,
                                    deviceCountryCode: Int) -> TransactionDetailPopoverDisplayable? {
    return nil
  }

  func detailCellActionableItem(at indexPath: IndexPath) -> TransactionDetailCellActionable? {
    return nil
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
    items += [
      generator.lightningTransfer(walletTxType: walletTransactionType, direction: .out), //load
      generator.lightningTransfer(walletTxType: walletTransactionType, direction: .in), //withdraw
      generator.genericOnChainTransactionWithPrivateMemo(direction: .out),
      generator.genericOnChainTransactionWithPrivateMemo(direction: .in)
    ]
  }

}

class MockTransactionHistoryLightningDataSource: MockTransactionHistoryDataSource {

  init() {
    super.init(walletTxType: .lightning)
    items += [
      generator.lightningTransfer(walletTxType: walletTransactionType, direction: .in), //load
      generator.lightningTransfer(walletTxType: walletTransactionType, direction: .out), //withdraw
      generator.lightningInvoice(hours: 42),
      generator.lightningInvoice(hours: nil) //expired
    ]
  }

}
