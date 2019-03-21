//
//  AppCoordinator+SerialQueueManagerTypeDelegate.swift
//  DropBit
//
//  Created by Mitch on 1/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Alamofire
import UIKit
import CNBitcoinKit
import MMDrawerController
import Moya
import Permission
import AVFoundation
import PromiseKit
import CoreData
import os.log

extension AppCoordinator: SerialQueueManagerDelegate {

  func syncManagerDidRequestBackgroundContext() -> NSManagedObjectContext {
    return persistenceManager.createBackgroundContext()
  }

  func syncManagerDidFinishSync() {
    self.trackIfUserHasABalance()
    self.persistenceCacheDataWorker.trackTypesOfTransactionsAndCacheIfNecessary()
  }

  func syncManagerDidSetWalletManager(walletManager: WalletManagerType, in context: NSManagedObjectContext) -> Promise<Void> {
    self.walletManager = walletManager
    return self.registerAndPersistWallet(in: context).asVoid()
  }

  func syncManagerDidRequestDependencies(in context: NSManagedObjectContext) -> Promise<SyncDependencies> {
    return predefineSyncDependencies(in: context, inBackground: false)
  }

  func showAlertsForSyncedChanges(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.showAlertsForAddressRequestUpdates(in: context)
      .then(in: context) { _ -> Promise<Void> in
        // Skip showing banners for transactions downloaded during initial sync
        guard self.persistenceManager.date(for: .lastSuccessfulSyncCompletedAt) != nil else {
          return Promise.value(())
        }
        return self.showAlertsForIncomingTransactions(in: context)
    }
  }

  func predefineSyncDependencies(in context: NSManagedObjectContext, inBackground background: Bool) -> Promise<SyncDependencies> {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "sync_transactions")

    guard (launchStateManager.userAuthenticated && self.isReadyToEnterApp) || background else {
      os_log("**Sync routine prevented by pending pin entry or verification step", log: logger, type: .debug)
      return Promise(error: SyncRoutineError.notReady)
    }

    // Ensure the wallet is using the words from the keychain before sending any requests, especially deverification checks
    guard let keychainWords = self.persistenceManager.walletWords() else {
      os_log("wallet does not yet exist, stopping sync", log: logger, type: .debug)
      return Promise(error: SyncRoutineError.missingRecoveryWords)
    }

    guard let wmgr = walletManager else {
      os_log("wallet manager does not exist in sync routine", log: logger, type: .error)
      return Promise(error: SyncRoutineError.missingWalletManager)
    }
    wmgr.resetWallet(with: keychainWords)  // this is a safety precaution to ensure the current wallet instance contains current words

    guard let txDataWorker = createTransactionDataWorker(),
      let walletWorker = createWalletAddressDataWorker() else {
        return Promise(error: SyncRoutineError.missingWorkers)
    }

    guard let dbWorker = self.createDatabaseMigrationWorker(in: context) else {
      os_log("database migration worker does not exist in sync routine", log: logger, type: .error)
      return Promise(error: SyncRoutineError.missingDatabaseMigrationWorker)
    }

    let keychainWorker = self.createKeychainMigrationWorker()
    let contactCacheMigrationWorker = self.createContactCacheMigrationWorker()

    let syncHelpers = SyncDependencies(
      walletManager: wmgr,
      keychainWords: keychainWords,
      bgContext: context,
      txDataWorker: txDataWorker,
      walletWorker: walletWorker,
      databaseMigrationWorker: dbWorker,
      keychainMigrationWorker: keychainWorker,
      contactCacheMigrationWorker: contactCacheMigrationWorker,
      persistenceManager: persistenceManager,
      networkManager: networkManager,
      connectionManager: connectionManager,
      delegate: self
    )
    os_log("Sync dependencies satisfied, will continue with sync", log: logger, type: .debug)
    return Promise.value(syncHelpers)
  }

  func handleReachabilityError(_ underlyingError: MoyaError) {
    self.connectionManager.setAPIUnreachable(true)
  }

  /// This should only be called in response to errors on the getUser and getWallet routes to prevent unintended deverification
  func handleAuthorizationError(_ networkError: CKNetworkError, recordType: RecordType, in context: NSManagedObjectContext) {
    guard case let .shouldUnverify(moyaError, recordType) = networkError else {
      return
    }

    switch recordType {
    case .user:
      context.performAndWait {
        self.unverifyUser(forError: moyaError, recordType: recordType, in: context)
      }

    case .wallet:
      context.performAndWait {
        self.unverifyUser(forError: moyaError, recordType: recordType, in: context)
        self.persistenceManager.removeWalletId(in: context)
      }

    case .unknown:
      break
    }
  }

  func handleInvalidResponseError(_ networkError: CKNetworkError) {
    self.connectionManager.setAPIUnreachable(true)

    // Send flare
    let errorDescription = networkError.errorDescription ?? "(no description)"
    let eventValue = AnalyticsEventValue(key: .invalidServerResponse, value: errorDescription)
    self.analyticsManager.track(event: .invalidServerResponse, with: eventValue)
  }

  private func unverifyUser(forError error: MoyaError, recordType: RecordType, in context: NSManagedObjectContext) {
    let isDeviceUUIDMismatch = error.responseDescription.contains(NetworkErrorIdentifier.deviceUUIDMismatch.rawValue)

    let errorMessage: String
    if isDeviceUUIDMismatch {
      errorMessage = "The phone number associated with this device is no longer registered. A new device has been registered with this phone number."
    } else {
      errorMessage = "The phone number associated with this device has been unregistered."
    }

    // Prevent showing banner if they have already been unverified
    if self.persistenceManager.userVerificationStatus(in: context) == .verified {
      self.alertManager.showBanner(with: errorMessage, duration: .default, alertKind: .error)

      let debugMessage = "Failed to get \(recordType.rawValue): \(error.responseDescription)"
      let eventValue = AnalyticsEventValue(key: .errorMessage, value: debugMessage)
      self.analyticsManager.track(event: .phoneAutoDeverified, with: eventValue)
    }

    self.persistenceManager.unverifyUser(in: context)
  }

  func handleMissingWalletError(_ error: CKPersistenceError) {
    if walletManager == nil {
      resetWalletManagerIfNeeded()
    }

    if walletManager == nil {  // if still nil
      let action = AlertActionConfiguration(title: "OK", style: .default, action: nil)
      let description = "The app failed to obtain access to the iOS keychain. For your security, please force close the app and try again."
      let viewModel = AlertControllerViewModel(
        title: "Something went wrong",
        description: description,
        image: nil,
        style: .alert,
        actions: [action]
      )
      let alertController = alertManager.alert(from: viewModel)
      navigationController.topViewController()?.present(alertController, animated: true, completion: nil)
    }
  }

}
