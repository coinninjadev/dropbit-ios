//
//  AppCoordinator+SerialQueueManagerTypeDelegate.swift
//  DropBit
//
//  Created by Mitch on 1/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Alamofire
import UIKit
import Moya
import Permission
import AVFoundation
import PromiseKit
import CoreData

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

  func syncManagerDidRequestDependencies(in context: NSManagedObjectContext, inBackground: Bool) -> Promise<SyncDependencies> {
    return predefineSyncDependencies(in: context, inBackground: inBackground)
  }

  func showAlertsForSyncedChanges(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.showAlertsForAddressRequestUpdates(in: context)
      .then(in: context) { _ -> Promise<Void> in
        // Skip showing banners for transactions downloaded during initial sync
        guard self.persistenceManager.brokers.activity.lastSuccessfulSync != nil else {
          return Promise.value(())
        }
        return self.showAlertsForIncomingTransactions(in: context)
    }
  }

  func predefineSyncDependencies(in context: NSManagedObjectContext, inBackground background: Bool) -> Promise<SyncDependencies> {

    let localWorkerFactory = workerFactory()

    guard (launchStateManager.userAuthenticated && self.verificationSatisfied) || background || launchStateManager.upgradeInProgress else {
      log.event("Sync routine prevented by pending pin entry or verification step")
      return Promise(error: DBTError.SyncRoutine.notReady)
    }

    // Ensure the wallet is using the words from the keychain before sending any requests, especially deverification checks
    guard let keychainWords = self.persistenceManager.brokers.wallet.walletWords() else {
      log.event("wallet does not yet exist, stopping sync")
      return Promise(error: DBTError.SyncRoutine.missingRecoveryWords)
    }

    guard let wmgr = walletManager else {
      log.error("wallet manager does not exist in sync routine")
      return Promise(error: DBTError.SyncRoutine.missingWalletManager)
    }
    wmgr.resetWallet(with: keychainWords)  // this is a safety precaution to ensure the current wallet instance contains current words

    guard let txDataWorker = localWorkerFactory.createTransactionDataWorker(),
      let walletWorker = localWorkerFactory.createWalletAddressDataWorker(delegate: self) else {
        return Promise(error: DBTError.SyncRoutine.missingWorkers)
    }

    guard let dbWorker = localWorkerFactory.createDatabaseMigrationWorker(in: context) else {
      log.error("database migration worker does not exist in sync routine")
      return Promise(error: DBTError.SyncRoutine.missingDatabaseMigrationWorker)
    }

    let keychainWorker = localWorkerFactory.createKeychainMigrationWorker()

    let syncHelpers = SyncDependencies(
      walletManager: wmgr,
      keychainWords: keychainWords,
      bgContext: context,
      txDataWorker: txDataWorker,
      walletWorker: walletWorker,
      databaseMigrationWorker: dbWorker,
      keychainMigrationWorker: keychainWorker,
      persistenceManager: persistenceManager,
      networkManager: networkManager,
      analyticsManager: analyticsManager,
      connectionManager: connectionManager,
      delegate: self,
      twitterAccessManager: twitterAccessManager,
      ratingAndReviewManager: ratingAndReviewManager,
      configManager: featureConfigManager
    )
    log.debug("Sync dependencies satisfied, will continue with sync")
    return Promise.value(syncHelpers)
  }

  func handleReachabilityError(_ underlyingError: MoyaError) {
    self.connectionManager.setAPIUnreachable(true)
  }

  /// This should only be called in response to errors on the getUser and getWallet routes to prevent unintended deverification
  func handleAuthorizationError(_ networkError: DBTError.Network, recordType: RecordType, in context: NSManagedObjectContext) {
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
        self.persistenceManager.brokers.wallet.removeWalletId(in: context)
      }

    case .unknown:
      break
    }
  }

  func handleInvalidResponseError(_ networkError: DBTError.Network) {
    self.connectionManager.setAPIUnreachable(true)

    // Send flare
    let errorDescription = networkError.errorDescription ?? "(no description)"
    let eventValue = AnalyticsEventValue(key: .invalidServerResponse, value: errorDescription)
    self.analyticsManager.track(event: .invalidServerResponse, with: eventValue)
  }

  private func unverifyUser(forError error: MoyaError, recordType: RecordType, in context: NSManagedObjectContext) {
    let isDeviceUUIDMismatch = error.responseDescription.contains(NetworkErrorIdentifier.deviceUUIDMismatch.rawValue)

    var deviceDescriptions: [String] = []

    let verifiedTypes = persistenceManager.brokers.user.verifiedIdentities(in: context)
    if verifiedTypes.contains(.phone) {
      deviceDescriptions.append("phone number")
    }
    if verifiedTypes.contains(.twitter) {
      deviceDescriptions.append("Twitter account")
    }
    let deviceDescription = deviceDescriptions.joined(separator: " or ")
    let errorMessage: String
    if isDeviceUUIDMismatch {
      errorMessage = "The \(deviceDescription) associated with this device is no longer registered." +
      " A new device has been registered with this \(deviceDescription)."
    } else {
      errorMessage = "The \(deviceDescription) associated with this device has been unregistered."
    }

    // Prevent showing banner if they have already been unverified
    if self.persistenceManager.brokers.user.userVerificationStatus(in: context) == .verified {
      self.alertManager.showBanner(with: errorMessage, duration: .default, alertKind: .error)

      let debugMessage = "Failed to get \(recordType.rawValue): \(error.responseDescription)"
      let eventValue = AnalyticsEventValue(key: .errorMessage, value: debugMessage)
      self.analyticsManager.track(event: .phoneAutoDeverified, with: eventValue)
      self.analyticsManager.track(property: MixpanelProperty(key: .isDropBitMeEnabled, value: false))
    }

    self.persistenceManager.brokers.user.unverifyUser(in: context)
  }

  func handleMissingWalletError(_ error: DBTError.Persistence) {
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
