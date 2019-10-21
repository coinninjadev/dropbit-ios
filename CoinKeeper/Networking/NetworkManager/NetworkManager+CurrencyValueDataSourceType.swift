//
//  NetworkManager+CurrencyValueDataSourceType.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol CurrencyValueDataSourceType: AnyObject {

  /// Provides a closure to be called by the delegate, which passes back the latest ExchangeRates
  /// Also, checks the exchange rates and posts a notification if they have been updated
  func latestExchangeRates(responseHandler: ExchangeRatesRequest)

  /// Returns latestFees wrapped in a Promise
  func latestFees() -> Promise<Fees>

}

// This timeout ensures we don't fetch exchange rates or fees more frequently than the specified interval in seconds
private let sTimeoutIntervalBetweenNetworkRequests: TimeInterval  = 5.0

/// Follows names of API
enum ResponseFeeType: String {
  case good, better, best
}

/// The rate should represent the amount of currency equal to 1 BTC
typealias ExchangeRates = [CurrencyCode: Double]

/// The closure type to be passed to the AppCoordinator when requesting the latest exchange rates.
/// This closure should be called on the main queue.
typealias ExchangeRatesRequest = (ExchangeRates) -> Void

/// The fee values represent the current cost of a transaction in satoshis/byte
typealias Fees = [ResponseFeeType: Double]

/// The closure type to be passed to the AppCoordinator when requesting the latest fees.
/// This closure should be called on the main queue.
typealias FeesRequest = (Fees) -> Void

extension NetworkManager: CurrencyValueDataSourceType {

  func latestExchangeRates(responseHandler: ExchangeRatesRequest) {
    // return latest exchange rates
    let usdRate = self.persistenceManager.brokers.checkIn.cachedBTCUSDRate
    responseHandler([.BTC: 1.0, .USD: usdRate])

    // re-fetch the latest exchange rates
    refetchLatestMetadataIfNecessary()
  }

  func latestFees() -> Promise<Fees> {
    return Promise { seal in
      let broker = self.persistenceManager.brokers.checkIn
      seal.fulfill([.best: broker.cachedBestFee,
                    .better: broker.cachedBetterFee,
                    .good: broker.cachedGoodFee])

      // re-fetch the latest fees
      self.refetchLatestMetadataIfNecessary()
    }
  }

  // MARK: Private
  /// Conditionally update metadata if stale
  private func refetchLatestMetadataIfNecessary() {
    let rateCheckTimestamp = Date()
    if rateCheckTimestamp.timeIntervalSince(lastExchangeRateCheck) > sTimeoutIntervalBetweenNetworkRequests {
      lastExchangeRateCheck = rateCheckTimestamp
      updateCachedMetadata()
        .catch(self.handleUpdateCachedMetadataError)
    }
  }

  /// Unconditionally update metadata from check-in api (fees, price, and blockheight)
  @discardableResult
  func updateCachedMetadata() -> Promise<CheckInResponse> {
    let context = persistenceManager.viewContext
    let walletId = self.persistenceManager.brokers.wallet.walletId(in: context)
    let broker = persistenceManager.brokers.checkIn
    guard walletId != nil else {
      let fees = FeesResponse(fast: broker.cachedBestFee, med: broker.cachedBetterFee, slow: broker.cachedGoodFee)
      let pricing = PriceResponse(last: broker.cachedBTCUSDRate)
      let response = CheckInResponse(blockheight: broker.cachedBlockHeight, fees: fees, pricing: pricing)
      return Promise.value(response)
    }

    return checkIn()
      .then { self.handleCheckIn(response: $0) }
  }

  /// Exposed as `internal` for testing purposes, but should only be called from `updateCachedMetadata` in the promise chain.
  /// Should not be exposed in NetworkManagerType protocol.
  func handleCheckIn(response: CheckInResponse) -> Promise<CheckInResponse> {
    let broker = persistenceManager.brokers.checkIn
    broker.cachedBestFee = max(response.fees.best, 0)
    broker.cachedBetterFee = max(response.fees.better, 0)
    broker.cachedGoodFee = max(response.fees.good, 0)
    broker.cachedBTCUSDRate = (response.pricing.last > 0) ? response.pricing.last : broker.cachedBTCUSDRate
    broker.cachedBlockHeight = (response.blockheight > 0) ? response.blockheight : broker.cachedBlockHeight
    CKNotificationCenter.publish(key: .didUpdateFees)
    CKNotificationCenter.publish(key: .didUpdateExchangeRates, userInfo: ["value": broker.cachedBTCUSDRate])
    return Promise { $0.fulfill(response) }
  }

}
