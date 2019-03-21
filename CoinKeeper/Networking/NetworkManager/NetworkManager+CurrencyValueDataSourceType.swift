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

enum FeeType: String {
  case good, better, best
}

/// The rate should represent the amount of currency equal to 1 BTC
typealias ExchangeRates = [CurrencyCode: Double]

/// The closure type to be passed to the AppCoordinator when requesting the latest exchange rates.
/// This closure should be called on the main queue.
typealias ExchangeRatesRequest = (ExchangeRates) -> Void

/// The fee values represent the current cost of a transaction in satoshis/byte
typealias Fees = [FeeType: Double]

/// The closure type to be passed to the AppCoordinator when requesting the latest fees.
/// This closure should be called on the main queue.
typealias FeesRequest = (Fees) -> Void

extension NetworkManager: CurrencyValueDataSourceType {

  func latestExchangeRates(responseHandler: ExchangeRatesRequest) {
    // return latest exchange rates
    let usdRate = self.cachedBTCUSDRate
    responseHandler([.BTC: 1.0, .USD: usdRate])

    // re-fetch the latest exchange rates
    refetchLatestMetadataIfNecessary()
  }

  func latestFees() -> Promise<Fees> {
    return Promise { seal in
      let bestFee = self.cachedBestFee
      let betterFee = self.cachedBetterFee
      let goodFee = self.cachedGoodFee
      seal.fulfill([.best: bestFee, .better: betterFee, .good: goodFee])

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
    let context = persistenceManager.createBackgroundContext()
    var walletId: String?
    context.performAndWait {
      walletId = self.persistenceManager.walletId(in: context)
    }
    guard walletId != nil else {
      let fees = FeesResponse(max: cachedBestFee, avg: cachedBetterFee, min: cachedGoodFee)
      let pricing = PriceResponse(last: cachedBTCUSDRate)
      let response = CheckInResponse(blockheight: cachedBlockheight, fees: fees, pricing: pricing)
      return Promise.value(response)
    }

    return walletCheckIn()
      .then { self.handleCheckIn(response: $0) }
  }

  /// Exposed as `internal` for testing purposes, but should only be called from `updateCachedMetadata` in the promise chain.
  /// Should not be exposed in NetworkManagerType protocol.
  func handleCheckIn(response: CheckInResponse) -> Promise<CheckInResponse> {
    cachedBestFee = max(response.fees.best, 0)
    cachedBetterFee = max(response.fees.better, 0)
    cachedGoodFee = max(response.fees.good, 0)
    cachedBTCUSDRate = (response.pricing.last > 0) ? response.pricing.last : cachedBTCUSDRate
    cachedBlockheight = (response.blockheight > 0) ? response.blockheight : cachedBlockheight
    CKNotificationCenter.publish(key: .didUpdateFees)
    CKNotificationCenter.publish(key: .didUpdateExchangeRates, userInfo: ["value": cachedBTCUSDRate])
    return Promise { $0.fulfill(response) }
  }

  private var cachedBTCUSDRate: Double {
    get { return persistenceManager.double(for: .exchangeRateBTCUSD) }
    set { persistenceManager.set(newValue, for: .exchangeRateBTCUSD) }
  }

  private var cachedBlockheight: Int {
    get { return persistenceManager.integer(for: .blockheight) }
    set { persistenceManager.set(newValue, for: .blockheight) }
  }

  private var cachedBestFee: Double {
    get { return persistenceManager.double(for: .feeBest) }
    set { persistenceManager.set(newValue, for: .feeBest) }
  }

  private var cachedBetterFee: Double {
    get { return persistenceManager.double(for: .feeBetter) }
    set { persistenceManager.set(newValue, for: .feeBetter) }
  }

  private var cachedGoodFee: Double {
    get { return persistenceManager.double(for: .feeGood) }
    set { persistenceManager.set(newValue, for: .feeGood) }
  }
}
