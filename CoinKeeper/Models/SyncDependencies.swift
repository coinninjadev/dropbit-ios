//
//  SyncDependencies.swift
//  DropBit
//
//  Created by BJ Miller on 12/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

struct SyncDependencies {
  let walletManager: WalletManagerType
  let keychainWords: [String]
  let bgContext: NSManagedObjectContext
  let txDataWorker: TransactionDataWorkerType
  let walletWorker: WalletAddressDataWorkerType
  let databaseMigrationWorker: DatabaseMigrationWorker
  let keychainMigrationWorker: KeychainMigrationWorker
  let persistenceManager: PersistenceManagerType
  let networkManager: NetworkManagerType
  let analyticsManager: AnalyticsManagerType
  let connectionManager: ConnectionManagerType
  // swiftlint:disable:next weak_delegate
  let delegate: SerialQueueManagerDelegate
  let twitterAccessManager: TwitterAccessManagerType
  let ratingAndReviewManager: RatingAndReviewManagerType
  let configManager: FeatureConfigManagerType
}
