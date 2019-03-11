//
//  NetworkManager+WalletAddressRequestRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

typealias AddressRequestPatch = (requestId: String, patch: WalletAddressRequest)

protocol WalletAddressRequestRequestable: AnyObject {
  func createAddressRequest(body: RequestAddressBody) -> Promise<WalletAddressRequestResponse>
  func getSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]>
  func getWalletAddressRequests(forSide side: WalletAddressRequestSide) -> Promise<[WalletAddressRequestResponse]>
  func updateWalletAddressRequest(for id: String, with request: WalletAddressRequest) -> Promise<WalletAddressRequestResponse>
}

extension WalletAddressRequestRequestable {
  func updateWalletAddressRequest(withPatch details: AddressRequestPatch) -> Promise<WalletAddressRequestResponse> {
    return updateWalletAddressRequest(for: details.requestId, with: details.patch)
  }
}

extension NetworkManager: WalletAddressRequestRequestable {

  func updateWalletAddressRequest(for id: String, with request: WalletAddressRequest) -> Promise<WalletAddressRequestResponse> {
    return cnProvider.request(WalletAddressRequestsTarget.update(id, request))
  }

  func createAddressRequest(body: RequestAddressBody) -> Promise<WalletAddressRequestResponse> {
    return cnProvider.request(WalletAddressRequestsTarget.create(body))
  }

  func getSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]> {
    return getWalletAddressRequests(forSide: .sent).filterValues { $0.isSatisfiedForSending }
  }

  func getWalletAddressRequests(forSide side: WalletAddressRequestSide) -> Promise<[WalletAddressRequestResponse]> {
    return cnProvider.requestList(WalletAddressRequestsTarget.get(side))
  }

}
