//
//  SerialQueueManager.swift
//  DropBit
//
//  Created by Mitch on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PromiseKit
import Moya

enum WalletSyncType: String {
  case comprehensive
  case standard
}

/// Used to distinguish the kinds of operations in the queue
enum AsyncOperationType: CustomStringConvertible {

  case syncWallet(WalletSyncType)
  case deleteWallet

  var description: String {
    switch self {
    case .deleteWallet:             return "deleteWallet"
    case .syncWallet(let syncType): return "syncWallet.\(syncType.rawValue)"
    }
  }

  func isEqual(to operationType: AsyncOperationType, ignoringAssociatedValues: Bool) -> Bool {
    switch self {
    case .syncWallet(let selfSyncType):
      switch operationType {
      case .syncWallet(let operationSyncType):
        let associatedTypesMatch = (selfSyncType == operationSyncType)
        return ignoringAssociatedValues ? true : associatedTypesMatch

      default:
        return false
      }

    case .deleteWallet:
      switch operationType {
      case .deleteWallet:   return true
      default:              return false
      }
    }
  }

  var walletSyncType: WalletSyncType? {
    if case let .syncWallet(syncType) = self {
      return syncType
    } else {
      return nil
    }
  }

}

enum EnqueueingPolicy {

  /// Compares both the AsyncOperationType and any associated value that it has.
  /// Adds new operation to the queue if no matches exist.
  case skipIfSpecificOperationExists

  /// Ignores comparing any associated value of the AsyncOperationType.
  /// Adds new operation to the queue if no matches exist.
  case skipIfSimilarOperationExists

  /// Ignores operations currently in the queue and always enqueues this operation.
  case always
}

struct SyncConfig {
  let blockHeight: Int?
}

protocol NetworkErrorDelegate: AnyObject {
  func handleAuthorizationError(_ networkError: CKNetworkError, recordType: RecordType, in context: NSManagedObjectContext)
  func handleInvalidResponseError(_ networkError: CKNetworkError)
  func handleReachabilityError(_ underlyingError: MoyaError)
}

protocol SerialQueueManagerDelegate: WalletSyncDelegate & NetworkErrorDelegate {
  var launchStateManager: LaunchStateManagerType { get }
}

protocol SerialQueueManagerType: class {
  var queue: OperationQueueType { get }
  var timer: Timer { get }
  var delegate: SerialQueueManagerDelegate? { get set }
  var walletSyncOperationFactory: WalletSyncOperationFactory? { get }

  func enqueueWalletSyncIfAppropriate(type: WalletSyncType,
                                      policy: EnqueueingPolicy,
                                      completion: CKErrorCompletion?,
                                      fetchResult: ((UIBackgroundFetchResult) -> Void)?)

  func enqueueOperationIfAppropriate(_ operation: AsynchronousOperation, policy: EnqueueingPolicy)
  func enqueueOptionalIncrementalSync()
}

class SerialQueueManager: SerialQueueManagerType {

  var queue: OperationQueueType
  var timer: Timer = Timer()
  weak var delegate: SerialQueueManagerDelegate?
  private let syncTimerIntervalInSeconds: Int = 30

  required init() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    self.queue = queue
    resetSyncTimer()
  }

  lazy var walletSyncOperationFactory: WalletSyncOperationFactory? = {
    guard let delegate = self.delegate else { return nil }
    return WalletSyncOperationFactory(delegate: delegate)
  }()

  private func resetSyncTimer() {
    timer.invalidate()
    let interval = TimeInterval(syncTimerIntervalInSeconds)
    timer = Timer.scheduledTimer(
      timeInterval: interval,
      target: self,
      selector: #selector(syncTimerDidFire),
      userInfo: nil,
      repeats: true
    )
  }

  func enqueueOperationIfAppropriate(_ operation: AsynchronousOperation, policy: EnqueueingPolicy) {
    let operationType = operation.operationType
    guard shouldEnqueueOperation(ofType: operationType, policy: policy) else { return }
    self.queue.addOperation(operation)
  }

  private func shouldEnqueueOperation(ofType type: AsyncOperationType, policy: EnqueueingPolicy) -> Bool {
    switch policy {
    case .always:
      return true

    case .skipIfSimilarOperationExists:
      let looselyMatchingOperations = self.queue.operations(ofType: type, ignoringAssociatedType: true)
      return looselyMatchingOperations.isEmpty

    case .skipIfSpecificOperationExists:
      let specificMatchingOperations = self.queue.operations(ofType: type, ignoringAssociatedType: false)
      return specificMatchingOperations.isEmpty
    }
  }

  func enqueueOptionalIncrementalSync() {
    self.enqueueWalletSyncIfAppropriate(type: .standard,
                                        policy: .skipIfSimilarOperationExists,
                                        completion: nil,
                                        fetchResult: nil)
  }

  func enqueueWalletSyncIfAppropriate(type: WalletSyncType,
                                      policy: EnqueueingPolicy,
                                      completion: CKErrorCompletion?,
                                      fetchResult: ((UIBackgroundFetchResult) -> Void)?) {
    guard let queueDelegate = self.delegate,
      let operationFactory = self.walletSyncOperationFactory else {
        completion?(SyncRoutineError.missingQueueDelegate)
        fetchResult?(.failed)
        return
    }

    guard self.shouldEnqueueOperation(ofType: .syncWallet(type), policy: policy) else {
      completion?(nil)
      fetchResult?(.noData)
      return
    }

    guard !queueDelegate.launchStateManager.upgradeInProgress else {
      completion?(nil)
      fetchResult?(.noData)
      return
    }

    let context = queueDelegate.syncManagerDidRequestBackgroundContext()
    operationFactory.createSyncOperation(ofType: type, completion: completion, fetchResult: fetchResult, in: context)
      .done { [weak self] operation in
        guard let strongSelf = self else { return }
        strongSelf.enqueueOperationIfAppropriate(operation, policy: policy)
      }.cauterize()
  }

  @objc private func syncTimerDidFire() {
    enqueueOptionalIncrementalSync()
  }

}
