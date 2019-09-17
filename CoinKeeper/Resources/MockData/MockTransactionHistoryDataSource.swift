//
//  MockTransactionHistoryDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class MockTransactionHistoryOnChainDataSource: TransactionHistoryDataSourceType {

  private let items: [TransactionSummaryCellDisplayable]

  let walletTransactionType: WalletTransactionType = .onChain

  weak var delegate: TransactionHistoryDataSourceDelegate?

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

  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable {
    return items[indexPath.row]
  }

  func detailCellViewModel(at indexPath: IndexPath,
                           rates: ExchangeRates,
                           currencies: CurrencyPair,
                           deviceCountryCode: Int) -> OldTransactionDetailCellViewModel? {
    return nil
  }

  func numberOfSections() -> Int {
    return 1
  }

  func numberOfItems(inSection section: Int) -> Int {
    return items.count
  }

}

class MockTransactionHistoryLightningDataSource: TransactionHistoryDataSourceType {

  private let items: [TransactionSummaryCellDisplayable]

  let walletTransactionType: WalletTransactionType = .lightning

  weak var delegate: TransactionHistoryDataSourceDelegate?

  init() {
    let gen = MockLightningDataGenerator()
    self.items = [
      gen.pendingInvoice,
      gen.lightningWithdraw,
      gen.coffee,
      gen.expiredInvoice,
      gen.loadLightning,
      gen.paidInvoice,
      gen.expiredPhoneInvite
    ]
  }

  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable {
    return items[indexPath.row]
  }

  func detailCellViewModel(at indexPath: IndexPath,
                           rates: ExchangeRates,
                           currencies: CurrencyPair,
                           deviceCountryCode: Int) -> OldTransactionDetailCellViewModel? {
    return nil
  }

  func numberOfSections() -> Int {
    return 1
  }

  func numberOfItems(inSection section: Int) -> Int {
    return items.count
  }

}
