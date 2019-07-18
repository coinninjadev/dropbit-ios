//
//  BalanceDisplayable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CoreData

/// Holds the block notification token until the BalanceDataSource is deinitialized
class BalanceUpdateManager {
  var willSaveNotificationToken: NotificationToken?
  var didSaveNotificationToken: NotificationToken?
  var balanceChangesObserved = false
}

protocol BalanceDataSource: CoreDataObserver {
  func balanceNetPending() -> NSDecimalNumber
  func spendableBalanceNetPending() -> NSDecimalNumber
  var balanceUpdateManager: BalanceUpdateManager { get }
}

extension BalanceDataSource {

  /**
   Monitors save notifications where AddressTransactionSummary and/or Invitation were affected and publishes a notification in response.
   This ignores changes made in child contexts until they are saved in the root context. (Filtering by context.name may be necessary.)
   The conforming object should call this function as soon as possible.
   */
  func registerForBalanceSaveNotifications() {
    observeContextSaveNotifications()
  }

  func setContextNotificationTokens(willSaveToken: NotificationToken, didSaveToken: NotificationToken) {
    self.balanceUpdateManager.willSaveNotificationToken = willSaveToken
    self.balanceUpdateManager.didSaveNotificationToken = didSaveToken
  }

  func handleWillSaveContext(_ context: NSManagedObjectContext) {
    // Observe the willSave notification so that we can still access the managed objects in case of deletion.
    var relevantInserts = 0, relevantUpdates = 0, relevantDeletions = 0
    context.performAndWait {
      relevantInserts = context.insertedObjects.filter { self.objectIsBalanceRelevant($0) }.count
      relevantUpdates = context.updatedObjects.filter { self.objectIsBalanceRelevant($0) }.count
      relevantDeletions = context.deletedObjects.filter { self.objectIsBalanceRelevant($0) }.count
    }

    // Set flag on balanceUpdateManager so that the notification is posted when didSaveNotification is observed
    let totalChanges = relevantInserts + relevantUpdates + relevantDeletions
    self.balanceUpdateManager.balanceChangesObserved = (totalChanges > 0)
  }

  func handleDidSaveContext(_ context: NSManagedObjectContext) {
    if self.balanceUpdateManager.balanceChangesObserved {
      CKNotificationCenter.publish(key: .didUpdateBalance)
      self.balanceUpdateManager.balanceChangesObserved = false
    }
  }

  private func objectIsBalanceRelevant(_ object: NSManagedObject) -> Bool {
    guard let objectEntityName = object.entity.managedObjectClassName else { return false }
    let relevantEntityNames: [String] = [CKMAddressTransactionSummary.entity(), CKMInvitation.entity()].compactMap { $0.managedObjectClassName }
    return relevantEntityNames.contains(objectEntityName)
  }

}

/**
 Holds the exchange rates returned by the CurrencyValueManager as well as
 the block notification token until the view controller is deinitialized.
 */
class ExchangeRateManager {
  var exchangeRates: ExchangeRates = [:]
  var notificationToken: NotificationToken?
  var balanceToken: NotificationToken?

  init() {
    let cachedExchangeRate = CKUserDefaults().standardDefaults.double(forKey: CKUserDefaults.Key.exchangeRateBTCUSD.defaultsString)
    self.exchangeRates = [.BTC: cachedExchangeRate, .USD: 1]
  }
}

/// Conforming object should provide both exchange rates and the current wallet balance
typealias ConvertibleBalanceProvider = CurrencyValueDataSourceType & BalanceDataSource

protocol BalanceDisplayable: ExchangeRateUpdateable, BalanceUpdateable {

  var balanceProvider: ConvertibleBalanceProvider? { get } // implementation should be a weak reference
  var balanceContainer: BalanceContainer! { get } // IBOutlet
  var primaryBalanceCurrency: CurrencyCode { get }
  var balanceLeftButtonType: BalanceContainerLeftButtonType { get }

}

extension BalanceDisplayable where Self: UIViewController {

  var currencyValueManager: CurrencyValueDataSourceType? {
    return balanceProvider
  }

  // overrides implementation in ExchangeRateUpdateable
  private func subscribeToRateUpdates() {
    // The observer block token is automatically deregistered when the rateManager is deallocated from the view controller
    rateManager.notificationToken = CKNotificationCenter.subscribe(key: .didUpdateExchangeRates, object: nil, queue: nil, using: { [weak self] _ in
      self?.updateRatesAndBalances()
    })

    rateManager.balanceToken = CKNotificationCenter.subscribe(key: .didUpdateBalance, object: nil, queue: nil) { [weak self] (_) in
      self?.updateRatesAndBalances()
    }
  }

  /// Call this on viewDidLoad
  func subscribeToRateAndBalanceUpdates() {
    subscribeToRateUpdates()
    subscribeToBalanceUpdates()
  }

  /// Call this on viewDidLoad and in the notification block of registerForRateUpdates()
  func updateRatesAndBalances() {

    // Calling updateRates() here relies on latestExchangeRates being non-escaping (synchronous),
    // so that rateManager.exchangeRates are set before the below code executes
    updateRatesWithLatest()

    updateViewWithBalance()
    didUpdateExchangeRateManager(self.rateManager)
  }

  /// Called in response to .didUpdateBalance notification in BalanceUpdateable
  func updateViewWithBalance() {
    let dataSource = updatedDataSource()
    balanceContainer.update(with: dataSource)
  }

  private func updatedDataSource() -> BalanceContainerDataSource {
    // Prevent ever showing a negative balance
    var sanitizedBalance: NSDecimalNumber = .zero
    if let calculatedBalance = balanceProvider?.balanceNetPending(), calculatedBalance.isPositiveNumber {
      sanitizedBalance = calculatedBalance
    }

    let rates = rateManager.exchangeRates
    let converter = CurrencyConverter(fromBtcTo: .USD, fromAmount: sanitizedBalance, rates: rates)

    return BalanceContainerDataSource(
      leftButtonType: balanceLeftButtonType,
      converter: converter,
      primaryCurrency: primaryBalanceCurrency)
  }

}
