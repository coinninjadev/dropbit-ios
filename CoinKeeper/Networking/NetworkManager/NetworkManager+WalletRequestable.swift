//
//  NetworkManager+WalletRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol WalletRequestable: AnyObject {
  func createWallet(withPublicKey key: String, walletFlags: Int) -> Promise<WalletResponse>
  func updateWallet(withPublicKey key: String, walletFlags: Int) -> Promise<WalletResponse>
  func getWallet() -> Promise<WalletResponse>
  func walletCheckIn() -> Promise<CheckInResponse>
  func resetWallet() -> Promise<Void>
}

extension NetworkManager: WalletRequestable {

  func createWallet(withPublicKey key: String, walletFlags: Int) -> Promise<WalletResponse> {
    let body = CreateWalletBody(publicKeyString: key, flags: walletFlags)
    return cnProvider.request(WalletTarget.create(body))
  }

  func updateWallet(withPublicKey key: String, walletFlags: Int) -> Promise<WalletResponse> {
    let body = CreateWalletBody(publicKeyString: key, flags: walletFlags)
    return cnProvider.request(WalletTarget.update(body))
  }

  func getWallet() -> Promise<WalletResponse> {
    return cnProvider.request(WalletTarget.get)
  }

  func walletCheckIn() -> Promise<CheckInResponse> {
    return cnProvider.request(WalletCheckInTarget.get)
  }

  func resetWallet() -> Promise<Void> {
    return cnProvider.requestVoid(WalletTarget.reset)
  }

}
