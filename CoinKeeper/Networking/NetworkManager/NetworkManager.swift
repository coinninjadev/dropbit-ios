//
//  NetworkManager.swift
//  CoinKeeper
//
//  Created by Bill Feth on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import Moya
import OAuthSwift

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
  TwitterRequestable &
  NewsDataRequestable &
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
  func handleUpdateCachedMetadataError(error: Error)
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
  let blockstreamProvider = BlockstreamProvider()

  var lastExchangeRateCheck = Date(timeIntervalSince1970: 0)
  var lastFeesCheck = Date(timeIntervalSince1970: 0)
  var twitterOAuthManager: OAuth1Swift

  init(persistenceManager: PersistenceManagerType,
       analyticsManager: AnalyticsManagerType = AnalyticsManager(),
       coinNinjaProvider: CoinNinjaProviderType = CoinNinjaProvider()) {

    self.persistenceManager = persistenceManager
    self.analyticsManager = analyticsManager
    self.cnProvider = coinNinjaProvider

    self.twitterOAuthManager = OAuth1Swift(
      consumerKey: twitterOAuth.consumerKey,
      consumerSecret: twitterOAuth.consumerSecret,
      requestTokenUrl: twitterOAuth.requestTokenURL,
      authorizeUrl: twitterOAuth.authorizeURL,
      accessTokenUrl: twitterOAuth.accessTokenURL
    )

    self.cnProvider.headerDelegate = self
  }

  func resetTwitterOAuthManager() {
    self.twitterOAuthManager = OAuth1Swift(
      consumerKey: twitterOAuth.consumerKey,
      consumerSecret: twitterOAuth.consumerSecret,
      requestTokenUrl: twitterOAuth.requestTokenURL,
      authorizeUrl: twitterOAuth.authorizeURL,
      accessTokenUrl: twitterOAuth.accessTokenURL
    )
  }

  func start() {
    // Setup exchange rate, network fees, block height, etc.
    updateCachedMetadata()
      .catch(self.handleUpdateCachedMetadataError)
  }

  func handleUpdateCachedMetadataError(error: Error) {
    if let networkError = error as? CKNetworkError {
      switch networkError {
      case .reachabilityFailed(let moyaError):
        log.error(moyaError, message: nil)
        if let data = moyaError.response?.data,
          let responseError = try? JSONDecoder().decode(CoinNinjaErrorResponse.self, from: data),
          responseError.error == NetworkErrorIdentifier.missingSignatureHeader.rawValue {
          guard self.walletDelegate?.mainWalletManager() == nil else { return }
          self.walletDelegate?.resetWalletManagerIfNeeded()
          if self.walletDelegate?.mainWalletManager() != nil {
            self.updateCachedMetadata()
          }
        }

      default: break
      }
    }
  }

}
