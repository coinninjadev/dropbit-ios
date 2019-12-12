//
//  WalletSyncOperationFactory.swift
//  DropBit
//
//  Created by Ben Winters on 2/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CoreData
import UIKit
import Moya

protocol WalletSyncDelegate: AnyObject {
  func syncManagerDidRequestDependencies(in context: NSManagedObjectContext, inBackground: Bool) -> Promise<SyncDependencies>
  func syncManagerDidRequestBackgroundContext() -> NSManagedObjectContext
  func syncManagerDidFinishSync()
  func showAlertsForSyncedChanges(in context: NSManagedObjectContext) -> Promise<Void>
  func syncManagerDidSetWalletManager(walletManager: WalletManagerType, in context: NSManagedObjectContext) -> Promise<Void>
  func handleMissingWalletError(_ error: CKPersistenceError)
}

class WalletSyncOperationFactory {

  weak var delegate: SerialQueueManagerDelegate?
  var walletNeedsUpdate = false

  init(delegate: SerialQueueManagerDelegate) {
    self.delegate = delegate
  }

  func performOnChainOnlySync(in context: NSManagedObjectContext) -> Promise<Void> {
    guard let queueDelegate = self.delegate else {
      return Promise(error: SyncRoutineError.missingQueueDelegate)
    }

    return queueDelegate.syncManagerDidRequestDependencies(in: context, inBackground: false)
      .then { self.onChainOnlySync(with: $0, in: context) }
  }

  func createSyncOperation(ofType walletSyncType: WalletSyncType,
                           completion: CKErrorCompletion?,
                           fetchResult: ((UIBackgroundFetchResult) -> Void)?,
                           in context: NSManagedObjectContext) -> Promise<AsynchronousOperation> {
    guard let queueDelegate = self.delegate else {
      return Promise.init(error: SyncRoutineError.missingQueueDelegate)
    }

    let inBackground = (fetchResult != nil)

    return queueDelegate.syncManagerDidRequestDependencies(in: context, inBackground: inBackground)
      .then(in: context) { dependencies -> Promise<AsynchronousOperation> in
        let operation = AsynchronousOperation(operationType: .syncWallet(walletSyncType))
        let bgContext = dependencies.bgContext
        let isFullSync = walletSyncType == .comprehensive

        operation.task = { [weak self, weak innerOp = operation] in
          guard let strongSelf = self, let strongOperation = innerOp else { return }

          let backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
          var caughtError: Error?
          let walletDebugDesc = strongSelf.walletDebugDescription(with: dependencies, in: bgContext)
          log.logMessage(walletDebugDesc, privateArgs: [], level: .info, location: nil)
          log.info("Sync routine: Starting.")
          strongSelf.performSync(with: dependencies, fullSync: isFullSync, in: bgContext)
            .catch { error in
              log.error(error, message: "Sync routine: caught error.")
              caughtError = error
              strongSelf.handleSyncRoutineError(error, in: bgContext)
            }
            .finally {
              log.info("Sync routine: Finishing...")
              var contextHasInsertionsOrUpdates = false
              var receivedFunds = false
              bgContext.perform {
                contextHasInsertionsOrUpdates = (bgContext.insertedObjects.isNotEmpty || bgContext.persistentUpdatedObjects.isNotEmpty)
                let receivedOnChain = bgContext.insertedObjects.compactMap { $0 as? CKMTransaction }.isNotEmpty
                let receivedLightning = bgContext.insertedObjects.compactMap { $0 as? CKMLNLedgerEntry }.isNotEmpty
                receivedFunds = receivedOnChain || receivedLightning
                do {
                  log.info("Sync routine: Saving database...")
                  try bgContext.saveRecursively()
                  log.info("Sync routine: Database saved.")
                } catch {
                  log.contextSaveError(error)
                }

                DispatchQueue.main.async {
                  CKNotificationCenter.publish(key: .didFinishSync, object: nil, userInfo: nil)
                  CKNotificationCenter.publish(key: .didUpdateBalance, object: nil, userInfo: nil)

                  dependencies.persistenceManager.brokers.activity.lastSuccessfulSync = Date()
                  dependencies.ratingAndReviewManager.promptForReviewIfNecessary(didReceiveFunds: receivedFunds)
                  completion?(caughtError) //Only call completion handler once

                  strongSelf.delegate?.syncManagerDidFinishSync()

                  if let fetchResultHandler = fetchResult {
                    let result: UIBackgroundFetchResult = contextHasInsertionsOrUpdates ? .newData : .noData
                    fetchResultHandler(result)
                  }

                  log.info("Sync routine: Finished.")
                  strongOperation.finish()
                  UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
              }
          }
        }

        return Promise.value(operation)
      }
  }

  private func walletDebugDescription(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> String {
    let walletId = dependencies.persistenceManager.brokers.wallet.walletId(in: context) ?? "-"
    let pubkey = dependencies.walletManager.hexEncodedPublicKey
    return "Wallet ID: \(walletId) -- Public Key: \(pubkey)"
  }

  private func performSync(with dependencies: SyncDependencies,
                           fullSync: Bool,
                           in context: NSManagedObjectContext) -> Promise<Void> {
    return dependencies.databaseMigrationWorker.migrateIfPossible()
      .then { _ in dependencies.keychainMigrationWorker.migrateIfPossible() }
      .then(in: context) { self.checkAndVerifyUser(with: dependencies, in: context) }
      .then(in: context) { self.checkAndVerifyWallet(with: dependencies, in: context) }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllOnChainTransactions(in: context, fullSync: fullSync) }
      .get { _ in dependencies.connectionManager.setAPIUnreachable(false) }
      .then(in: context) { self.updateLightningAccount(with: dependencies, in: context) }
      .get { account in self.updateLightningAccountStatusAfterSuccessfulResponse(dependencies, account: account) }
      .then(in: context) { _ in dependencies.txDataWorker.performFetchAndStoreAllLightningTransactions(in: context, fullSync: fullSync) }
      .recover { self.handleThunderdomeSyncError(with: $0, dependencies: dependencies) }
      .then(in: context) { _ in dependencies.walletWorker.updateServerPoolAddresses(in: context) }
      .then(in: context) { dependencies.walletWorker.updateReceivedAddressRequests(in: context) }
      .then(in: context) { _ in dependencies.walletWorker.updateSentAddressRequests(in: context) }
      .recover(self.recoverSyncError)
      .then(in: context) { _ in self.fetchAndFulfillReceivedAddressRequests(with: dependencies, in: context) }
      .then(in: context) { _ in dependencies.delegate.showAlertsForSyncedChanges(in: context) }
      .then(in: context) { _ in dependencies.twitterAccessManager.inflateTwitterUsersIfNeeded(in: context) }
      .then(in: context) { _ in self.updateWalletIfNeeded(dependencies: dependencies, context: context) }
  }

  private func updateLightningAccountStatusAfterSuccessfulResponse(_ dependencies: SyncDependencies, account: LNAccountResponse) {
    if account.locked {
      dependencies.analyticsManager.track(property: MixpanelProperty(key: .lightningLockedStatus, value: true))
      dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .locked
      CKNotificationCenter.publish(key: .didLockLightning)
    } else {
      dependencies.analyticsManager.track(property: MixpanelProperty(key: .lightningLockedStatus, value: false))
      dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .unlocked
      CKNotificationCenter.publish(key: .didUnlockLightning)
    }
  }

  private func handleThunderdomeSyncError(with error: Error, dependencies: SyncDependencies) -> Promise<Void> {
    log.error(error, message: "received error from thunderdome")

    guard let statusCode = (error as? MoyaError)?.response?.statusCode, statusCode == 503 else {
      return Promise(error: error)
    }
    dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .unavailable
    CKNotificationCenter.publish(key: .lightningUnavailable)
    return Promise.value(())
  }

  private func onChainOnlySync(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    return dependencies.databaseMigrationWorker.migrateIfPossible()
      .then { _ in dependencies.keychainMigrationWorker.migrateIfPossible() }
      .then(in: context) { self.checkAndVerifyWallet(with: dependencies, in: context) }
      .then { dependencies.networkManager.checkIn() }
      .then { dependencies.persistenceManager.brokers.checkIn.processCheckIn(response: $0) }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllOnChainTransactions(in: context, fullSync: true) }
      .get { _ in dependencies.connectionManager.setAPIUnreachable(false) }
  }

  private func recoverSyncError(_ error: Error) -> Promise<Void> {
    if let providerError = error as? CKNetworkError {
      switch providerError {
      case .userNotVerified:  return Promise.value(())
      default:                return Promise(error: error)
      }
    } else {
      return Promise(error: error)
    }
  }

  func updateLightningAccount(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<LNAccountResponse> {
    return dependencies.networkManager.getOrCreateLightningAccount()
      .get(in: context) { dependencies.persistenceManager.brokers.lightning.persistAccountResponse($0, in: context) }
  }

  private func checkAndVerifyUser(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let userId: String? = dependencies.persistenceManager.brokers.user.userId(in: context)

    if userId != nil {
      log.info("Sync routine: Found user ID, calling /user GET.")
      return dependencies.networkManager.getUser().asVoid()
    } else {
      log.info("Sync routine: no user ID found. Continuing.")
      return Promise.value(())
    }
  }

  private func checkAndVerifyWallet(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let walletId: String? = dependencies.persistenceManager.brokers.wallet.walletId(in: context)
    if walletId != nil {
      return dependencies.networkManager
        .getWallet()
        .recover { (error: Error) -> Promise<WalletResponse> in
          if case CKNetworkError.unauthorized = error {
            var flagsParser = WalletFlagsParser(flags: 0).setVersion(.v0).setPurpose(.BIP49)
            if let words = dependencies.persistenceManager.keychainManager.retrieveValue(for: .walletWords) as? [String] {
              let newWalletManager = WalletManager(words: words, persistenceManager: dependencies.persistenceManager)
              return dependencies.networkManager.createWallet(withPublicKey: newWalletManager.hexEncodedPublicKey, walletFlags: flagsParser.flags)
            } else if let words = dependencies.persistenceManager.keychainManager.retrieveValue(for: .walletWordsV2) as? [String] {
              flagsParser = flagsParser.setVersion(.v2).setPurpose(.BIP84)
              let newWalletManager = WalletManager(words: words, persistenceManager: dependencies.persistenceManager)
              return dependencies.networkManager.createWallet(withPublicKey: newWalletManager.hexEncodedPublicKey, walletFlags: flagsParser.flags)
            } else {
              return Promise(error: CKPersistenceError.noWalletWords)
            }
          } else {
            return Promise(error: error)
          }
      }
        .get(in: context) { try dependencies.persistenceManager.brokers.wallet.persistWalletResponse(from: $0, in: context) }
        .asVoid()
    } else { // walletId is nil
      guard let keychainWords = dependencies.persistenceManager.brokers.wallet.walletWords() else {
        return Promise { $0.reject(CKPersistenceError.noWalletWords) }
      }

      // Make sure we are registering a wallet with the words stored in the keychain
      let walletManager = WalletManager(words: keychainWords, persistenceManager: dependencies.persistenceManager)
      return dependencies.delegate.syncManagerDidSetWalletManager(walletManager: walletManager, in: context)
    }
  }

  func fetchAndFulfillReceivedAddressRequests(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let verificationStatus = dependencies.persistenceManager.brokers.user.userVerificationStatus(in: context)
    guard verificationStatus == .verified else { return Promise { $0.fulfill(()) } }
    return dependencies.walletWorker.fetchAndFulfillReceivedAddressRequests(in: context).asVoid()
  }

  private func handleSyncRoutineError(_ error: Error, in context: NSManagedObjectContext) {
    if let persistenceError = error as? CKPersistenceError {
      switch persistenceError {
      case .noWalletWords:
        delegate?.handleMissingWalletError(persistenceError)
      default: break
      }
    } else if let networkError = error as? CKNetworkError {
      switch networkError {
      case .reachabilityFailed(let moyaError):
        delegate?.handleReachabilityError(moyaError)

      case .invalidValue, .responseMissingValue:
        delegate?.handleInvalidResponseError(networkError)

      case .shouldUnverify(_, let recordType):
        delegate?.handleAuthorizationError(networkError, recordType: recordType, in: context)

      default: break
      }
    }
  }

  private func updateWalletIfNeeded(dependencies: SyncDependencies, context: NSManagedObjectContext) -> Promise<Void> {
    guard let wallet = CKMWallet.find(in: context) else { return Promise.value(()) } // wallet should always exist here, so continue promise chain
    let parser = WalletFlagsParser(flags: wallet.flags)
    let localIsBackedUp = parser.isWalletBackedUp
    let localHasBTCBalance = parser.hasBTCBalance
    let localHasLightningBalance = parser.hasLightningBalance

    let isBackedUp = dependencies.persistenceManager.brokers.wallet.walletWordsBackedUp()
    let spendableBalance = dependencies.walletManager.spendableBalance(in: context)
    let hasBTCBalance = spendableBalance.onChain > 0
    let hasLightningBalance = spendableBalance.lightning > 0

    var hasChanges = false
    hasChanges = hasChanges || (localIsBackedUp != isBackedUp)
    hasChanges = hasChanges || (localHasBTCBalance != hasBTCBalance)
    hasChanges = hasChanges || (localHasLightningBalance != hasLightningBalance)

    if hasChanges || self.walletNeedsUpdate {
      self.walletNeedsUpdate = false
      let maybeReferrer = dependencies.persistenceManager.brokers.user.referredBy
      parser.setBackedUp(isBackedUp).setHasBTCBalance(hasBTCBalance).setHasLightningBalance(hasLightningBalance)
      return dependencies.networkManager.updateWallet(walletFlags: parser.flags, referrer: maybeReferrer)
        .done(in: context) { try? dependencies.persistenceManager.brokers.wallet.persistWalletResponse(from: $0, in: context) }
    } else {
      return Promise.value(())
    }
  }

}
