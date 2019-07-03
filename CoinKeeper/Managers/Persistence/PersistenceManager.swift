//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import Foundation
import CoreData
import PromiseKit

class PersistenceManager: PersistenceManagerType {

  let keychainManager: PersistenceKeychainType
  let databaseManager: PersistenceDatabaseType
  let userDefaultsManager: PersistenceUserDefaultsType
  let contactCacheManager: ContactCacheManagerType
  let brokers: PersistenceBrokersType

  let hashingManager = HashingManager()

  init(
    keychainManager: PersistenceKeychainType = CKKeychain(),
    databaseManager: PersistenceDatabaseType = CKDatabase(),
    userDefaultsManager: PersistenceUserDefaultsType = CKUserDefaults(),
    contactCacheManager: ContactCacheManagerType = ContactCacheManager(),
    brokers: PersistenceBrokersType? = nil) {
    self.keychainManager = keychainManager
    self.databaseManager = databaseManager
    self.userDefaultsManager = userDefaultsManager
    self.contactCacheManager = contactCacheManager
    self.brokers = brokers ?? PersistenceBrokers(keychainManager: keychainManager,
                                                 databaseManager: databaseManager,
                                                 userDefaultsManager: userDefaultsManager)
  }

  func createBackgroundContext() -> NSManagedObjectContext {
    return databaseManager.createBackgroundContext()
  }

  func resetPersistence() throws {
    try self.brokers.wallet.resetWallet()
    self.userDefaultsManager.deleteAll()
    self.keychainManager.deleteAll()
  }

  func mainQueueContext() -> NSManagedObjectContext {
    return databaseManager.mainQueueContext
  }

  func persistentStore() -> NSPersistentStore? {
    return persistentStore(for: mainQueueContext())
  }

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
    return databaseManager.persistentStore(for: context)
  }

  func persistReceivedSharedPayloads(_ payloads: [Data], in context: NSManagedObjectContext) {
    let hasher = self.hashingManager
    databaseManager.sharedPayloadManager.persistReceivedSharedPayloads(
      payloads,
      hasher: hasher,
      contactCacheManager: contactCacheManager,
      in: context)
  }

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext) {
    databaseManager.persistTransactionSummaries(from: responses, in: context)
    updateReceiveAddressGaps(in: context)
  }

  private func updateReceiveAddressGaps(in context: NSManagedObjectContext) {
    let usedDerivativePaths = CKMDerivativePath.findAllReceivePathsWithAddressTransactionSummaries(in: context)
    let usedIndexes = usedDerivativePaths.map { $0.index }
    if let maxUsedIndex = usedIndexes.max() {
      let fullSet = Set(Array(0...maxUsedIndex))
      let usedSet = Set(usedIndexes)
      let gaps: Set<Int> = fullSet.subtracting(usedSet)
      self.brokers.wallet.receiveAddressIndexGaps = gaps

    } else {
      self.brokers.wallet.receiveAddressIndexGaps = []
    }
  }

  func walletAndUserId(in context: NSManagedObjectContext) -> Promise<(walletId: String, userId: String)> {
    return Promise { seal in
      guard let walletId = self.databaseManager.walletId(in: context) else { throw CKPersistenceError.missingValue(key: "wallet ID") }
      guard let userId = self.databaseManager.userId(in: context) else { throw CKPersistenceError.missingValue(key: "user ID") }
      seal.fulfill((walletId, userId))
    }
  }

  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders> {
    return walletAndUserId(in: context).map { DefaultRequestHeaders(walletId: $0.walletId, userId: $0.userId) }
  }

  func matchContactsIfPossible() {
    databaseManager.matchContactsIfPossible(with: contactCacheManager)
  }

}
