//
//  MockNetworkManager+WalletAddressRequestRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: WalletAddressRequestRequestable {

  func createAddressRequest(body: RequestAddressBody) -> Promise<WalletAddressRequestResponse> {
    return Promise { _ in }
  }

  func getSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]> {
    return Promise { _ in }
  }

  func getWalletAddressRequests(forSide side: WalletAddressRequestSide) -> Promise<[WalletAddressRequestResponse]> {
    guard let response = getWalletAddressRequestsResponse else { return Promise { _ in } }
    return Promise { seal in
      seal.fulfill([response])
    }
  }

  func updateWalletAddressRequest(for id: String, with request: WalletAddressRequest) -> Promise<WalletAddressRequestResponse> {
    guard let response = updateWalletAddressRequestResponse else { return Promise { _ in } }
    return Promise { seal in
      seal.fulfill(response)
    }
  }

}
