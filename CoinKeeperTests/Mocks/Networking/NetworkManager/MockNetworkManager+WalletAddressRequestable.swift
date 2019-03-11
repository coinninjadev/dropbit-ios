//
//  MockNetworkManager+WalletAddressRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: WalletAddressRequestable {

  func addWalletAddress(body: AddWalletAddressBody) -> Promise<WalletAddressResponse> {
    return Promise { _ in }
  }

  func getWalletAddresses() -> Promise<[WalletAddressResponse]> {
    return Promise { _ in }
  }

  func deleteWalletAddress(_ address: String) -> Promise<Void> {
    return Promise.value(())
  }

  func queryWalletAddresses(phoneNumberHashes: [String]) -> Promise<[WalletAddressesQueryResponse]> {
    return Promise { _ in }
  }

}
