//
//  TransactionHistoryDisplayableDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

protocol TransactionHistoryDataSourceChangeDelegate: AnyObject {
  func transactionDataSourceWillChange()
  func transactionDataSourceDidChange()
}

/// This protocol abstracts the UICollectionViewDataSource so that it can load data based off of Core Data fetch results
/// or data from an array of mock view models that conform to TransactionDetailCellDisplayable.
protocol TransactionHistoryDataSourceType: AnyObject {
  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair) -> TransactionSummaryCellDisplayable
  //TODO: func detailCellDisplayableItem(at indexPath: IndexPath, rates: ExchangeRates, currencies: CurrencyPair) -> TransactionDetailCellDisplayable
  func numberOfSections() -> Int
  func numberOfItems(inSection section: Int) -> Int
  var walletTransactionType: WalletTransactionType { get }
  var changeDelegate: TransactionHistoryDataSourceChangeDelegate? { get set }
}

class TransactionHistoryOnChainDataSource: NSObject, TransactionHistoryDataSourceType, NSFetchedResultsControllerDelegate {

  let frc: NSFetchedResultsController<CKMTransaction>
  let walletTransactionType: WalletTransactionType = .onChain

  weak var changeDelegate: TransactionHistoryDataSourceChangeDelegate?

  init(context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.sortDescriptors = CKMTransaction.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    self.frc = controller
    super.init()
    controller.delegate = self
    try? self.frc.performFetch()
  }

  func summaryCellDisplayableItem(at indexPath: IndexPath, rates: ExchangeRates, currencies: CurrencyPair) -> TransactionSummaryCellDisplayable {
    let amountDetails = TransactionAmountDetails(btcAmount: .zero, fiatCurrency: .USD, exchangeRates: rates)
    return TransactionSummaryCellViewModel(selectedCurrency: .BTC, walletTxType: walletTransactionType,
                                           status: .completed, isValidTransaction: true, isLightningTransfer: false,
                                           btcAddress: nil, lightningInvoice: nil, memo: nil,
                                           amountDetails: amountDetails, direction: .in, counterpartyConfig: nil)
  }

  func numberOfSections() -> Int {
    return frc.sections?.count ?? 0
  }

  func numberOfItems(inSection section: Int) -> Int {
    return frc.sections?[section].numberOfObjects ?? 0
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changeDelegate?.transactionDataSourceWillChange()
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changeDelegate?.transactionDataSourceDidChange()
  }

}

class TransactionHistoryLightningDataSource: NSObject, TransactionHistoryDataSourceType, NSFetchedResultsControllerDelegate {

  let frc: NSFetchedResultsController<CKMWalletEntry>
  let walletTransactionType: WalletTransactionType = .lightning
  weak var changeDelegate: TransactionHistoryDataSourceChangeDelegate?

  init(context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<CKMWalletEntry> = CKMWalletEntry.fetchRequest()
    fetchRequest.sortDescriptors = CKMWalletEntry.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    self.frc = controller
    super.init()
    controller.delegate = self
    try? self.frc.performFetch()
  }

  func summaryCellDisplayableItem(at indexPath: IndexPath, rates: ExchangeRates, currencies: CurrencyPair) -> TransactionSummaryCellDisplayable {
    return MockSummaryCellVM.testInstance()
//    let walletEntry = frc.object(at: indexPath)

//    let amountDetails = TransactionAmountDetails(btcAmount: .zero, fiatCurrency: currencies.fiat, exchangeRates: rates)
//    return TransactionSummaryCellViewModel(selectedCurrency: .BTC, walletTxType: .light,
//                                           status: .completed, isValidTransaction: true, isLightningTransfer: false,
//                                           btcAddress: nil, lightningInvoice: nil, memo: nil,
//                                           amountDetails: amountDetails, direction: .in, counterpartyConfig: nil)
  }

  func numberOfSections() -> Int {
    return frc.sections?.count ?? 0
  }

  func numberOfItems(inSection section: Int) -> Int {
    return frc.sections?[section].numberOfObjects ?? 0
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changeDelegate?.transactionDataSourceWillChange()
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changeDelegate?.transactionDataSourceDidChange()
  }

}
