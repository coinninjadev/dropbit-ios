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
  func createAddressRequest(body: WalletAddressRequestBody, preauthId: String?) -> Promise<WalletAddressRequestResponse>
  func getWalletAddressRequests(forSide side: WalletAddressRequestSide) -> Promise<[WalletAddressRequestResponse]>
  func updateWalletAddressRequest(for id: String, with request: WalletAddressRequest) -> Promise<WalletAddressRequestResponse>
}

extension WalletAddressRequestRequestable {
  func updateWalletAddressRequest(withPatch details: AddressRequestPatch) -> Promise<WalletAddressRequestResponse> {
    return updateWalletAddressRequest(for: details.requestId, with: details.patch)
  }

  func requestServerSendTweetForWalletAddressRequest(id: String) -> Promise<WalletAddressRequestResponse> {
    let request = WalletAddressRequest(suppress: false)
    return updateWalletAddressRequest(for: id, with: request)
  }
}

extension NetworkManager: WalletAddressRequestRequestable {

  func updateWalletAddressRequest(for id: String, with request: WalletAddressRequest) -> Promise<WalletAddressRequestResponse> {
    return cnProvider.request(WalletAddressRequestsTarget.update(id, request))
  }

  func createAddressRequest(body: WalletAddressRequestBody, preauthId: String?) -> Promise<WalletAddressRequestResponse> {
    var preauthBody = body
    preauthBody.preauthId = preauthId
    return cnProvider.request(WalletAddressRequestsTarget.create(preauthBody))
  }

  func getWalletAddressRequests(forSide side: WalletAddressRequestSide) -> Promise<[WalletAddressRequestResponse]> {
    return cnProvider.requestList(WalletAddressRequestsTarget.get(side))
  }

}
