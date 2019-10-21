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

  func detailPopoverDisplayableItem(at indexPath: IndexPath,
                                    rates: ExchangeRates,
                                    currencies: CurrencyPair,
                                    deviceCountryCode: Int) -> TransactionDetailPopoverDisplayable?

  func detailCellActionableItem(at indexPath: IndexPath) -> TransactionDetailCellActionable?

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
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)
    return TransactionSummaryCellViewModel(object: transaction, inputs: inputs)
  }

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable {
    let transaction = frc.object(at: indexPath)
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)
    return TransactionDetailInvalidCellViewModel(maybeInvalidObject: transaction, inputs: inputs) ??
      TransactionDetailCellViewModel(object: transaction, inputs: inputs)
  }

  func detailPopoverDisplayableItem(at indexPath: IndexPath,
                                    rates: ExchangeRates,
                                    currencies: CurrencyPair,
                                    deviceCountryCode: Int) -> TransactionDetailPopoverDisplayable? {
    let transaction = frc.object(at: indexPath)
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)
    return OnChainPopoverViewModel(object: transaction, inputs: inputs)
  }

  func detailCellActionableItem(at indexPath: IndexPath) -> TransactionDetailCellActionable? {
    return frc.object(at: indexPath)
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
    fetchRequest.predicate = CKPredicate.WalletEntry.notHidden()
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
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)
    return TransactionSummaryCellViewModel(object: vmObject, inputs: inputs)
  }

  func detailCellDisplayableItem(at indexPath: IndexPath,
                                 rates: ExchangeRates,
                                 currencies: CurrencyPair,
                                 deviceCountryCode: Int) -> TransactionDetailCellDisplayable {
    let walletEntry = frc.object(at: indexPath)
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)

    if let invoiceViewModelObject = LightningInvoiceViewModelObject(walletEntry: walletEntry) {
      return TransactionDetailInvoiceCellViewModel(object: invoiceViewModelObject, inputs: inputs)
    } else {
      let vmObject = viewModelObject(for: walletEntry)
      if let invalidViewModelObject = TransactionDetailInvalidCellViewModel(maybeInvalidObject: vmObject, inputs: inputs) {
        return invalidViewModelObject
      } else {
        return TransactionDetailCellViewModel(object: vmObject, inputs: inputs)
      }
    }
  }

  func detailPopoverDisplayableItem(at indexPath: IndexPath,
                                    rates: ExchangeRates,
                                    currencies: CurrencyPair,
                                    deviceCountryCode: Int) -> TransactionDetailPopoverDisplayable? {
    //This intentionally returns nil for ledger entries with type .lightning, no popover desired
    let walletEntry = frc.object(at: indexPath)
    guard let viewModelObject = LightningOnChainViewModelObject(walletEntry: walletEntry) else { return nil }
    let inputs = TransactionViewModelInputs(currencies: currencies, exchangeRates: rates, deviceCountryCode: deviceCountryCode)
    return OnChainPopoverViewModel(object: viewModelObject, inputs: inputs)
  }

  func detailCellActionableItem(at indexPath: IndexPath) -> TransactionDetailCellActionable? {
    return frc.object(at: indexPath)
  }

  private func viewModelObject(for walletEntry: CKMWalletEntry) -> TransactionDetailCellViewModelObject {
    if let invitationObject = LightningInvitationViewModelObject(walletEntry: walletEntry) {
      return invitationObject
    } else if let lightningInvoiceObject = LightningInvoiceViewModelObject(walletEntry: walletEntry) {
      return lightningInvoiceObject
    } else if let transactionObject = LightningTransactionViewModelObject(walletEntry: walletEntry) {
      return transactionObject
    } else if let tempLoadObject = LightningLoadTemporaryViewModelObject(walletEntry: walletEntry) {
      return tempLoadObject
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
