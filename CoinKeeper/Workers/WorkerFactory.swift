//
//  WorkerFactory.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PhoneNumberKit

/// The actual wallet manager object may change its seed words during the course of the app,
/// so we request the current instance of it each time through this provider.
protocol WalletManagerProvider: AnyObject {
  var walletManager: WalletManagerType? { get }
}

extension AppCoordinator: WalletManagerProvider { }

class WorkerFactory {

  let persistenceManager: PersistenceManagerType
  let networkManager: NetworkManagerType
  let analyticsManager: AnalyticsManagerType
  let phoneNumberKit: PhoneNumberKit
  weak var wmgrProvider: WalletManagerProvider?

  init(persistenceManager: PersistenceManagerType,
       networkManager: NetworkManagerType,
       analyticsManager: AnalyticsManagerType,
       phoneNumberKit: PhoneNumberKit,
       walletManagerProvider: WalletManagerProvider) {
    self.persistenceManager = persistenceManager
    self.networkManager = networkManager
    self.analyticsManager = analyticsManager
    self.phoneNumberKit = phoneNumberKit
    self.wmgrProvider = walletManagerProvider
  }

  /// This function ensures we are always working with the current instance of the WalletManager
  func createTransactionDataWorker() -> TransactionDataWorker? {
    guard let wmgr = wmgrProvider?.walletManager else { return nil }
    return TransactionDataWorker(walletManager: wmgr,
                                 persistenceManager: persistenceManager,
                                 networkManager: networkManager,
                                 analyticsManager: analyticsManager)
  }

  /// This function ensures we are always working with the current instance of the WalletManager
  func createWalletAddressDataWorker(delegate: InvitationWorkerDelegate) -> WalletAddressDataWorker? {
    guard let wmgr = wmgrProvider?.walletManager else { return nil }
    return WalletAddressDataWorker(walletManager: wmgr,
                                   persistenceManager: persistenceManager,
                                   networkManager: networkManager,
                                   analyticsManager: analyticsManager,
                                   phoneNumberKit: self.phoneNumberKit,
                                   invitationWorkerDelegate: delegate)
  }

  func createKeychainMigrationWorker() -> KeychainMigrationWorker {
    let factory = KeychainMigratorFactory(persistenceManager: persistenceManager)
    return KeychainMigrationWorker(migrators: factory.migrators())
  }

  func createContactCacheMigrationWorker(dataWorker: ContactCacheDataWorkerType) -> ContactCacheMigrationWorker {
    let factory = ContactCacheMigratorFactory(persistenceManager: persistenceManager,
                                              dataWorker: dataWorker)
    return ContactCacheMigrationWorker(migrators: factory.migrators())
  }

  func createMigratorFactory(in context: NSManagedObjectContext) -> DatabaseMigratorFactory? {
    guard let wmgr = wmgrProvider?.walletManager else { return nil }
    let addressDataSource = wmgr.createAddressDataSource()
    return DatabaseMigratorFactory(persistenceManager: persistenceManager, addressDataSource: addressDataSource, context: context)
  }

  func createDatabaseMigrationWorker(in context: NSManagedObjectContext) -> DatabaseMigrationWorker? {
    guard let factory = createMigratorFactory(in: context) else { return nil }
    let migrators = factory.migrators()
    return DatabaseMigrationWorker(migrators: migrators, in: context)
  }

}
