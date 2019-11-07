//
//  MockNetworkManager.swift
//  DropBitTests
//
//  Created by Bill Feth on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit
import OAuthSwift

class MockNetworkManager: NetworkManagerType {

  weak var walletDelegate: WalletDelegateType?
  weak var headerDelegate: HeaderDelegate?

  var persistenceManager: PersistenceManagerType
  var analyticsManager: AnalyticsManagerType

  var uiTestArguments: [UITestArgument] = []
  var twitterOAuthManager: OAuth1Swift = OAuth1Swift(consumerKey: "", consumerSecret: "")

  init(persistenceManager: PersistenceManagerType,
       analyticsManager: AnalyticsManagerType = AnalyticsManager()) {

    self.persistenceManager = persistenceManager
    self.analyticsManager = analyticsManager
  }

  // MARK: - Return values for extensions

  var wasAskedToFetchTransactionSummariesForAddresses = false
  var confirmFailedTransactionValueByTxid: [String: Bool] = [:]
  var latestExchangeRatesWasCalled = false
  var latestFeesWasCalled = false
  var getUserWasCalled = false
  var getWalletWasCalled = false
  var getUserError: CKNetworkError?
  var getWalletError: CKNetworkError?

  var walletCheckInShouldSucceed = true

  // MARK: Container values for mocked responses
  var updateWalletAddressRequestResponse: WalletAddressRequestResponse?
  var getWalletAddressRequestsResponse: WalletAddressRequestResponse?

  // MARK: - NetworkManagerType

  var startWasCalled = false
  func start() {
    startWasCalled = true
  }

  var updateCachedMetadataWasCalled = false
  func updateCachedMetadata() -> Promise<CheckInResponse> {
    updateCachedMetadataWasCalled = true
    // swiftlint:disable:next force_try
    let response = try! JSONDecoder().decode(CheckInResponse.self, from: WalletCheckInTarget.get.sampleData)
    return Promise.value(response)
  }

  func handleUpdateCachedMetadataError(error: Error) {}

}
