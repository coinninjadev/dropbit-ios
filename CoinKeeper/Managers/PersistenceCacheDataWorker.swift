//
//  PersistenceCacheDataWorker.swift
//  DropBit
//
//  Created by Mitch on 12/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol PersistenceCacheDataWorkerType {
  func trackTypesOfTransactionsAndCacheIfNecessary()
}

class PersistenceCacheDataWorker: PersistenceCacheDataWorkerType {

  let analyticsManager: AnalyticsManagerType
  let persistenceManager: PersistenceManagerType

  private var regularTransactionsCacheTuple: IncomingOutgoingTuple?
  private var dropbitTransactionsCacheTuple: IncomingOutgoingTuple?
  private var dateSinceLastCache: Date?

  private var dataNeedsRefreshed: Bool {
    guard let dateSinceLastCache = dateSinceLastCache,
      let cachedDateThiryMinutesInTheFuture = NSCalendar.current.date(byAdding: .minute, value: 30, to: dateSinceLastCache)
      else { return true }

    return cachedDateThiryMinutesInTheFuture < Date()
  }

  init(persistenceManager: PersistenceManagerType, analyticsManager: AnalyticsManagerType) {
    self.persistenceManager = persistenceManager
    self.analyticsManager = analyticsManager
  }

  func trackTypesOfTransactionsAndCacheIfNecessary() {
    if dataNeedsRefreshed {
      queryAndCacheTuples()
      trackTypesOfTransactions()
    }
  }

  private func queryAndCacheTuples() {
    dateSinceLastCache = Date()
    let bgContext = persistenceManager.createBackgroundContext()
    bgContext.perform { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.regularTransactionsCacheTuple = strongSelf.persistenceManager.containsRegularTransaction(in: bgContext)
      strongSelf.dropbitTransactionsCacheTuple = strongSelf.persistenceManager.containsDropbitTransaction(in: bgContext)
      strongSelf.trackTypesOfTransactions()
    }
  }

  private func trackTypesOfTransactions() {
    guard let dropbitTransactionsCacheTuple = dropbitTransactionsCacheTuple,
      let regularTransactionsCacheTuple = regularTransactionsCacheTuple else { return }
    analyticsManager.track(property: MixpanelProperty(key: .hasSent, value: regularTransactionsCacheTuple.outgoing))
    analyticsManager.track(property: MixpanelProperty(key: .hasReceived, value: regularTransactionsCacheTuple.incoming))
    analyticsManager.track(property: MixpanelProperty(key: .hasSentDropBit, value: dropbitTransactionsCacheTuple.outgoing))
    analyticsManager.track(property: MixpanelProperty(key: .hasReceivedDropBit, value: dropbitTransactionsCacheTuple.incoming))
  }
}
