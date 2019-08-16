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
              bgContext.performAndWait {
                do {
                  try bgContext.save()
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
                let result: UIBackgroundFetchResult = bgContext.insertedObjects.isNotEmpty ||
                  bgContext.updatedObjects.isNotEmpty ? .newData : .noData
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
      .then(in: context) { self.checkAndRecoverAuthorizationIds(with: dependencies, in: context) }
      .then(in: context) { self.updateLightningAccount(with: dependencies, in: context).asVoid() }
      .then(in: context) { dependencies.txDataWorker.performFetchAndStoreAllTransactionalData(in: context, fullSync: fullSync) }
      .get { _ in dependencies.connectionManager.setAPIUnreachable(false) }
      .then(in: context) { dependencies.walletWorker.updateServerPoolAddresses(in: context) }
      .then(in: context) { dependencies.walletWorker.updateReceivedAddressRequests(in: context) }
      .then(in: context) { _ in dependencies.walletWorker.updateSentAddressRequests(in: context) }
      .recover(self.recoverSyncError)
      .then(in: context) { _ in self.fetchAndFulfillReceivedAddressRequests(with: dependencies, in: context) }
      .then(in: context) { _ in dependencies.delegate.showAlertsForSyncedChanges(in: context) }
      .then(in: context) { _ in dependencies.twitterAccessManager.inflateTwitterUsersIfNeeded(in: context) }
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
        let wallet = CKMWallet.findOrCreate(in: context)
        dependencies.persistenceManager.brokers.lightning.persistAccountResponse(lnAccountResponse, forWallet: wallet, in: context)
    }
  }

  func checkAndRecoverAuthorizationIds(with dependencies: SyncDependencies, in context: NSManagedObjectContext) -> Promise<Void> {
    let walletId: String? = dependencies.persistenceManager.brokers.wallet.walletId(in: context)
    let userId: String? = dependencies.persistenceManager.brokers.user.userId(in: context)

    if userId != nil {
      return dependencies.networkManager.getUser().asVoid()

    } else if walletId != nil {
      return dependencies.networkManager.getWallet().asVoid()

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
