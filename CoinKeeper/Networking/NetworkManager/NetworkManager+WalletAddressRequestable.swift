//
//  NetworkManager+WalletAddressRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol WalletAddressRequestable: AnyObject {
  func addWalletAddress(body: AddWalletAddressBody) -> Promise<WalletAddressResponse>
  func getWalletAddresses() -> Promise<[WalletAddressResponse]>
  func deleteWalletAddress(_ address: String) -> Promise<Void>
  func queryWalletAddresses(identityHashes: [String]) -> Promise<[WalletAddressesQueryResponse]>
}

extension NetworkManager: WalletAddressRequestable {

  func addWalletAddress(body: AddWalletAddressBody) -> Promise<WalletAddressResponse> {
    return cnProvider.request(WalletAddressesTarget.create(body))
  }

  func getWalletAddresses() -> Promise<[WalletAddressResponse]> {
    return cnProvider.requestList(WalletAddressesTarget.get)
  }

  func deleteWalletAddress(_ address: String) -> Promise<Void> {
    return cnProvider.requestVoid(WalletAddressesTarget.delete(address))
  }

  func queryWalletAddresses(identityHashes: [String]) -> Promise<[WalletAddressesQueryResponse]> {
    let query = WalletAddressesElasticQuery(identityHashes: identityHashes)
    let body = ElasticRequest(query: query)
    return cnProvider.requestList(WalletAddressesQueryTarget.query(body))
  }

}
