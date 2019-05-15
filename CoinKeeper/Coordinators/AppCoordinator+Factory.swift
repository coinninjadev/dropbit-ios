//
//  AppCoordinator+Factory.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

extension AppCoordinator {

  /// This function ensures we are always working with the current instance of the WalletManager
  func createTransactionDataWorker() -> TransactionDataWorker? {
    guard let wmgr = walletManager else { return nil }
    return TransactionDataWorker(walletManager: wmgr,
                                 persistenceManager: persistenceManager,
                                 networkManager: networkManager,
                                 analyticsManager: analyticsManager)
  }

  /// This function ensures we are always working with the current instance of the WalletManager
  func createWalletAddressDataWorker() -> WalletAddressDataWorker? {
    guard let wmgr = walletManager else { return nil }
    return WalletAddressDataWorker(walletManager: wmgr,
                                   persistenceManager: persistenceManager,
                                   networkManager: networkManager,
                                   analyticsManager: analyticsManager,
                                   phoneNumberKit: self.phoneNumberKit,
                                   invitationWorkerDelegate: self)
  }

  func createDatabaseMigrationWorker(in context: NSManagedObjectContext) -> DatabaseMigrationWorker? {
    guard let factory = createMigratorFactory(in: context) else { return nil }
    let migrators = factory.migrators()
    return DatabaseMigrationWorker(migrators: migrators, in: context)
  }

  func createKeychainMigrationWorker() -> KeychainMigrationWorker {
    let factory = KeychainMigratorFactory(persistenceManager: persistenceManager)
    return KeychainMigrationWorker(migrators: factory.migrators())
  }

  func createContactCacheMigrationWorker() -> ContactCacheMigrationWorker {
    let factory = ContactCacheMigratorFactory(persistenceManager: persistenceManager,
                                              dataWorker: contactCacheDataWorker)
    return ContactCacheMigrationWorker(migrators: factory.migrators())
  }

  func createMigratorFactory(in context: NSManagedObjectContext) -> DatabaseMigratorFactory? {
    guard let wmgr = walletManager else { return nil }
    let addressDataSource = wmgr.createAddressDataSource()
    return DatabaseMigratorFactory(persistenceManager: persistenceManager, addressDataSource: addressDataSource, context: context)
  }

}
