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
import os.log

protocol WalletSyncDelegate: AnyObject {
  func syncManagerDidRequestDependencies(in context: NSManagedObjectContext) -> Promise<SyncDependencies>
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

  func createSyncOperation(ofType walletSyncType: WalletSyncType,
                           completion: CompletionHandler?,
                           fetchResult: ((UIBackgroundFetchResult) -> Void)?,
                           in context: NSManagedObjectContext) -> Promise<AsynchronousOperation> {
    guard let queueDelegate = self.delegate else {
      return Promise.init(error: SyncRoutineError.missingQueueDelegate)
    }

    return Promise { seal in
      let operation = AsynchronousOperation(operationType: .syncWallet(walletSyncType))
      queueDelegate.syncManagerDidRequestDependencies(in: context)
        .done(in: context) { dependencies in
          let bgContext = dependencies.bgContext
          let isFullSync = walletSyncType == .comprehensive

          let backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

          operation.task = { [weak self] sync in
            guard let strongSelf = self else {
              seal.reject(SyncRoutineError.missingSyncTask)
              return
            }

            var caughtError: Error?
            strongSelf.performSync(operation,
                              with: dependencies,
                              fullSync: isFullSync,
                              fetchResult: fetchResult,
                              in: bgContext)
              .catch(in: context) { error in
                caughtError = error
                strongSelf.handleSyncRoutineError(error, in: context)

              }.finally {
                context.performAndWait {
                  do {
                    try context.save()
                  } catch {
                    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.walletsyncoperationfactory", category: "perform_sync")
                    os_log("failed to save context in %@. error: %@", log: logger, type: .error, #function, error.localizedDescription)
                  }
                }
                CKNotificationCenter.publish(key: .didFinishSync, object: nil, userInfo: nil)
                CKNotificationCenter.publish(key: .didUpdateBalance, object: nil, userInfo: nil)

                dependencies.persistenceManager.brokers.activity.lastSuccessfulSync = Date()
                completion?(caughtError) //Only call completion handler once

                sync.finish()
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
            }
          }

          if operation.task != nil {
            seal.fulfill(operation)
          } else {
            seal.reject(SyncRoutineError.missingSyncTask)
          }
        }.catch { error in
          seal.reject(error)
      }
    }
  }

  private func performSync(_ operation: AsynchronousOperation,
                           with dependencies: SyncDependencies,
                           fullSync: Bool,
                           fetchResult: ((UIBackgroundFetchResult) -> Void)?,
                           in context: NSManagedObjectContext) -> Promise<Void> {
    return dependencies.databaseMigrationWorker.migrateIfPossible()
      .then(in: context) { self.checkAndRecoverAuthorizationIds(with: dependencies, in: context) }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllTransactionalData(in: context, fullSync: fullSync) }
      .get { _ in dependencies.connectionManager.setAPIUnreachable(false) }
      .then(in: context) { dependencies.walletWorker.updateServerPoolAddresses(in: context) }
      .then(in: context) { dependencies.walletWorker.updateReceivedAddressRequests(in: context) }
      .then(in: context) { _ in dependencies.walletWorker.updateSentAddressRequests(in: context) }
      .recover(self.recoverSyncError)
      .then(in: context) { _ in self.fetchAndFulfillReceivedAddressRequests(with: dependencies, in: context) }
      .then(in: context) { _ in dependencies.delegate.showAlertsForSyncedChanges(in: context) }
      .then(in: context) { _ in dependencies.twitterAccessManager.inflateTwitterUsersIfNeeded(in: context) }
      .done(in: context) {
        if let fetchResultHandler = fetchResult {
          let fetchResult: UIBackgroundFetchResult = context.insertedObjects.isNotEmpty ||
            context.updatedObjects.isNotEmpty ? .newData : .noData
          fetchResultHandler(fetchResult)
        }
    }
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

  func checkAndRecoverAuthorizationIds(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let walletId: String? = dependencies.persistenceManager.walletId(in: context)
    let userId: String? = dependencies.persistenceManager.userId(in: context)

    if userId != nil {
      return dependencies.networkManager.getUser().asVoid()

    } else if walletId != nil {
      return dependencies.networkManager.getWallet().asVoid()

    } else { // walletId is nil
      guard let keychainWords = dependencies.persistenceManager.walletWords() else {
        return Promise { $0.reject(CKPersistenceError.noWalletWords) }
      }

      // Make sure we are registering a wallet with the words stored in the keychain
      let walletManager = WalletManager(words: keychainWords, persistenceManager: dependencies.persistenceManager)
      return dependencies.delegate.syncManagerDidSetWalletManager(walletManager: walletManager, in: context)
    }
  }

  func fetchAndFulfillReceivedAddressRequests(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let verificationStatus = dependencies.persistenceManager.userVerificationStatus(in: context)
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
