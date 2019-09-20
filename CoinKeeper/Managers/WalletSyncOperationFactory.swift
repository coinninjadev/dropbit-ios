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

  init(delegate: SerialQueueManagerDelegate) {
    self.delegate = delegate
  }

  func createOnChainOnlySync(in context: NSManagedObjectContext) -> Promise<Void> {
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

        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        operation.task = { [weak self, weak innerOp = operation] in
          guard let strongSelf = self, let strongOperation = innerOp else { return }

          var caughtError: Error?
          strongSelf.performSync(with: dependencies, fullSync: isFullSync, in: bgContext)
            .catch(in: bgContext) { error in
              caughtError = error
              strongSelf.handleSyncRoutineError(error, in: bgContext)
            }
            .finally {
              var contextHasInsertionsOrUpdates = false
              bgContext.performAndWait {
                contextHasInsertionsOrUpdates = (bgContext.insertedObjects.isNotEmpty || bgContext.updatedObjects.isNotEmpty)
                do {
                  try bgContext.saveRecursively()
                } catch {
                  log.contextSaveError(error)
                }
              }

              CKNotificationCenter.publish(key: .didFinishSync, object: nil, userInfo: nil)
              CKNotificationCenter.publish(key: .didUpdateBalance, object: nil, userInfo: nil)

              dependencies.persistenceManager.brokers.activity.lastSuccessfulSync = Date()
              completion?(caughtError) //Only call completion handler once

              strongSelf.delegate?.syncManagerDidFinishSync()

              if let fetchResultHandler = fetchResult {
                let result: UIBackgroundFetchResult = contextHasInsertionsOrUpdates ? .newData : .noData
                fetchResultHandler(result)
              }

              strongOperation.finish()
              UIApplication.shared.endBackgroundTask(backgroundTaskId)
          }
        }

        return Promise.value(operation)
      }
  }

  private func performSync(with dependencies: SyncDependencies,
                           fullSync: Bool,
                           in context: NSManagedObjectContext) -> Promise<Void> {
    return dependencies.databaseMigrationWorker.migrateIfPossible()
      .then { _ in dependencies.keychainMigrationWorker.migrateIfPossible() }
      .then(in: context) { self.checkAndVerifyUser(with: dependencies, in: context) }
      .then(in: context) { self.checkAndVerifyWallet(with: dependencies, in: context) }
      .then(in: context) { self.updateLightningAccount(with: dependencies, in: context).asVoid() }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllOnChainTransactions(in: context, fullSync: fullSync) }
      .get { _ in dependencies.connectionManager.setAPIUnreachable(false) }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllLightningTransactions(in: context) }
      .then(in: context) { dependencies.walletWorker.updateServerPoolAddresses(in: context) }
      .then(in: context) { dependencies.walletWorker.updateReceivedAddressRequests(in: context) }
      .then(in: context) { _ in dependencies.walletWorker.updateSentAddressRequests(in: context) }
      .recover(self.recoverSyncError)
      .then(in: context) { _ in self.fetchAndFulfillReceivedAddressRequests(with: dependencies, in: context) }
      .then(in: context) { _ in dependencies.delegate.showAlertsForSyncedChanges(in: context) }
      .then(in: context) { _ in dependencies.twitterAccessManager.inflateTwitterUsersIfNeeded(in: context) }
  }

  private func onChainOnlySync(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    return dependencies.databaseMigrationWorker.migrateIfPossible()
      .then { _ in dependencies.keychainMigrationWorker.migrateIfPossible() }
      .then(in: context) { self.checkAndVerifyUser(with: dependencies, in: context) }
      .then(in: context) { self.checkAndVerifyWallet(with: dependencies, in: context) }
      .then { dependencies.networkManager.walletCheckIn() }
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
      .get(in: context) { lnAccountResponse in
        guard let wallet = CKMWallet.find(in: context) else { return }

        #if DEBUG //TODO: unlock wallet for debug builds only, remove later
        if lnAccountResponse.locked {
          CKNotificationCenter.publish(key: .didLockLightning)
          dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .locked
        } else {
          CKNotificationCenter.publish(key: .didUnlockLightning)
          dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .unlocked
        }
        #else
        BaseViewController.lockStatus = .locked
        dependencies.persistenceManager.brokers.preferences.lightningWalletLockedStatus = .locked
        CKNotificationCenter.publish(key: .didLockLightning)
        #endif

        dependencies.persistenceManager.brokers.lightning.persistAccountResponse(lnAccountResponse, forWallet: wallet, in: context)
    }
  }

  private func checkAndVerifyUser(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let userId: String? = dependencies.persistenceManager.brokers.user.userId(in: context)

    if userId != nil {
      return dependencies.networkManager.getUser().asVoid()
    } else {
      return Promise.value(())
    }
  }

  private func checkAndVerifyWallet(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let walletId: String? = dependencies.persistenceManager.brokers.wallet.walletId(in: context)
    if walletId != nil {
      return dependencies.networkManager
        .getWallet()
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

}
