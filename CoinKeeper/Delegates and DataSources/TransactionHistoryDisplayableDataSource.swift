//
//  TransactionHistoryDisplayableDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

protocol TransactionHistoryDataSourceDelegate: AnyObject {
  func transactionDataSourceWillChange()
  func transactionDataSourceDidChange()
}

/// This protocol abstracts the UICollectionViewDataSource so that it can load data based off of Core Data fetch results
/// or data from an array of mock view models that conform to TransactionDetailCellDisplayable.
protocol TransactionHistoryDataSourceType: AnyObject {
  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable

  func numberOfSections() -> Int
  func numberOfItems(inSection section: Int) -> Int
  var walletTransactionType: WalletTransactionType { get }
  var delegate: TransactionHistoryDataSourceDelegate? { get set }
}

class TransactionHistoryOnChainDataSource: NSObject, TransactionHistoryDataSourceType, NSFetchedResultsControllerDelegate {

  let frc: NSFetchedResultsController<CKMTransaction>
  let walletTransactionType: WalletTransactionType = .onChain

  weak var delegate: TransactionHistoryDataSourceDelegate?

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

  /// `currencies.primary` should be the SelectedCurrency of the user
  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable {
    let transaction = frc.object(at: indexPath)
    let selectedCurrency: SelectedCurrency = currencies.primary.isFiat ? .fiat : .BTC
    return TransactionSummaryCellViewModel(object: transaction,
                                           selectedCurrency: selectedCurrency,
                                           fiatCurrency: currencies.fiat,
                                           exchangeRates: rates,
                                           deviceCountryCode: deviceCountryCode)
  }

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable {
    let transaction = frc.object(at: indexPath)
    let selectedCurrency: SelectedCurrency = currencies.primary.isFiat ? .fiat : .BTC
    return TransactionDetailCellViewModel(object: transaction, selectedCurrency: selectedCurrency, fiatCurrency: currencies.fiat,
                                          exchangeRates: rates, deviceCountryCode: deviceCountryCode)
  }

  func numberOfSections() -> Int {
    return frc.sections?.count ?? 0
  }

  func numberOfItems(inSection section: Int) -> Int {
    return frc.sections?[section].numberOfObjects ?? 0
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.transactionDataSourceWillChange()
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.transactionDataSourceDidChange()
  }

}

class TransactionHistoryLightningDataSource: NSObject, TransactionHistoryDataSourceType, NSFetchedResultsControllerDelegate {

  let frc: NSFetchedResultsController<CKMWalletEntry>
  let walletTransactionType: WalletTransactionType = .lightning

  weak var delegate: TransactionHistoryDataSourceDelegate?

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

  func summaryCellDisplayableItem(at indexPath: IndexPath,
                                  rates: ExchangeRates,
                                  currencies: CurrencyPair,
                                  deviceCountryCode: Int) -> TransactionSummaryCellDisplayable {

    let walletEntry = frc.object(at: indexPath)
    let vmObject = viewModelObject(for: walletEntry)
    let selectedCurrency: SelectedCurrency = currencies.primary.isFiat ? .fiat : .BTC
    return TransactionSummaryCellViewModel(object: vmObject,
                                           selectedCurrency: selectedCurrency,
                                           fiatCurrency: currencies.fiat,
                                           exchangeRates: rates,
                                           deviceCountryCode: deviceCountryCode)
  }

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable {
    let walletEntry = frc.object(at: indexPath)
    let vmObject = viewModelObject(for: walletEntry)
    let selectedCurrency: SelectedCurrency = currencies.primary.isFiat ? .fiat : .BTC
    return MockDetailCellVM()
  }

  private func viewModelObject(for walletEntry: CKMWalletEntry) -> TransactionSummaryCellViewModelObject {
    if let lightningInvoiceObject = LightningInvoiceViewModelObject(walletEntry: walletEntry) {
      return lightningInvoiceObject
    } else if let lightningObject = LightningViewModelObject(walletEntry: walletEntry) {
      return lightningObject
    } else {
      return FallbackViewModelObject(walletTxType: .lightning)
    }
  }

  func numberOfSections() -> Int {
    return frc.sections?.count ?? 0
  }

  func numberOfItems(inSection section: Int) -> Int {
    return frc.sections?[section].numberOfObjects ?? 0
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.transactionDataSourceWillChange()
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.transactionDataSourceDidChange()
  }

}
