//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit
@testable import DropBit

class MockPersistenceManager: PersistenceManagerType {

  var keychainManager: PersistenceKeychainType
  var databaseManager: PersistenceDatabaseType
  var userDefaultsManager: PersistenceUserDefaultsType
  var contactCacheManager: ContactCacheManagerType
  var hashingManager: HashingManager = HashingManager()
  let brokers: PersistenceBrokersType

  var fakeCoinToUse: CNBBaseCoin = CNBBaseCoin(purpose: .BIP49, coin: .TestNet, account: 0)
  var usableCoin: CNBBaseCoin { return fakeCoinToUse }

  init(keychainManager: PersistenceKeychainType = MockPersistenceKeychainManager(store: MockKeychainAccessorType()),
       databaseManager: PersistenceDatabaseType = MockPersistenceDatabaseManager(),
       userDefaultsManager: PersistenceUserDefaultsType = MockUserDefaultsManager(),
       contactCacheManager: ContactCacheManagerType = MockContactCacheManager(),
       brokers: PersistenceBrokersType? = nil
    ) {
    self.keychainManager = keychainManager
    self.databaseManager = databaseManager
    self.userDefaultsManager = userDefaultsManager
    self.contactCacheManager = contactCacheManager
    let inputs = PersistenceBrokerInputs(keychain: keychainManager, database: databaseManager, defaults: userDefaultsManager)
    self.brokers = brokers ?? MockPersistenceBrokers(inputs: inputs)
  }

  func createBackgroundContext() -> NSManagedObjectContext {
    return databaseManager.createBackgroundContext()
  }

  var viewContext: NSManagedObjectContext {
    return databaseManager.viewContext
  }

  func persistentStore() -> NSPersistentStore? {
    return nil
  }

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
    return nil
  }

  func resetPersistence() {}

  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders> {
    return Promise { _ in }
  }

  func defaultHeaders(temporaryUserId: String, in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders> {
    return Promise { _ in }
  }

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext) {}

  func persistReceivedSharedPayloads(_ payloads: [Data],
                                     ofType walletTxType: WalletTransactionType,
                                     in context: NSManagedObjectContext) { }

  func persistReceivedAddressRequests(_ responses: [WalletAddressRequestResponse], in context: NSManagedObjectContext) { }

  func matchContactsIfPossible() {
    databaseManager.matchContactsIfPossible(with: self.contactCacheManager)
  }

}
