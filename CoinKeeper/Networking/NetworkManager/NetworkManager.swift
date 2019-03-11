//
//  NetworkManager.swift
//  CoinKeeper
//
//  Created by Bill Feth on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import os.log
import PromiseKit
import Moya

protocol NetworkManagerType: HeaderDelegate &
  AddressRequestable &
  BlockchainInfoRequestable &
  CurrencyValueDataSourceType &
  DeviceRequestable &
  DeviceEndpointRequestable &
  MerchantPaymentRequestRequestable &
  MessageRequestable &
  PricingRequestable &
  SubscribeToWalletRequestable &
  TransactionBroadcastable &
  TransactionRequestable &
  TransactionNotificationRequestable &
  UserRequestable &
  WalletRequestable &
  WalletAddressRequestable &
  WalletAddressRequestRequestable &
NotificationNetworkInteractable {

  var persistenceManager: PersistenceManagerType { get }
  var headerDelegate: HeaderDelegate? { get set }
  var walletDelegate: WalletDelegateType? { get set }

  func start()
  func updateCachedMetadata() -> Promise<CheckInResponse>

}

extension NetworkManagerType {

  func createHeaders(for bodyData: Data?) -> DefaultHeaders? {
    return self.headerDelegate?.createHeaders(for: bodyData)
  }

}

class NetworkManager: NetworkManagerType {

  weak var headerDelegate: HeaderDelegate?
  weak var walletDelegate: WalletDelegateType?

  let persistenceManager: PersistenceManagerType
  let analyticsManager: AnalyticsManagerType
  let cnProvider: CoinNinjaProviderType

  let blockchainInfoProvider = BlockchainInfoProvider()

  var lastExchangeRateCheck = Date(timeIntervalSince1970: 0)
  var lastFeesCheck = Date(timeIntervalSince1970: 0)

  let logger = OSLog(subsystem: "com.coinninja.NetworkManager", category: "network_requests")

  init(persistenceManager: PersistenceManagerType,
       analyticsManager: AnalyticsManagerType = AnalyticsManager(),
       coinNinjaProvider: CoinNinjaProviderType = CoinNinjaProvider()) {

    self.persistenceManager = persistenceManager
    self.analyticsManager = analyticsManager
    self.cnProvider = coinNinjaProvider

    self.cnProvider.headerDelegate = self
  }

  func start() {
    // Setup exchange rate, network fees, block height, etc.
    updateCachedMetadata()
  }

}
