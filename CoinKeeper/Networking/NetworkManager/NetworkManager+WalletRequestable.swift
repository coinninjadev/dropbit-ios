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
  func updateWallet(walletFlags: Int, referrer: String?) -> Promise<WalletResponse>
  func replaceWallet(body: ReplaceWalletBody) -> Promise<WalletResponse>
  func getWallet() -> Promise<WalletResponse>
  func walletCheckIn() -> Promise<CheckInResponse>
  func checkIn() -> Promise<CheckInResponse>
  func resetWallet() -> Promise<Void>
}

extension NetworkManager: WalletRequestable {

  func createWallet(withPublicKey key: String, walletFlags: Int) -> Promise<WalletResponse> {
    let body = CreateWalletBody(publicKeyString: key, flags: walletFlags)
    return cnProvider.request(WalletTarget.create(body))
  }

  func updateWallet(walletFlags: Int, referrer: String?) -> Promise<WalletResponse> {
    let body = UpdateWalletBody(flags: walletFlags, referrer: referrer)
    return cnProvider.request(WalletTarget.update(body))
  }

  func replaceWallet(body: ReplaceWalletBody) -> Promise<WalletResponse> {
    return cnProvider.request(WalletTarget.replace(body))
  }

  func getWallet() -> Promise<WalletResponse> {
    return cnProvider.request(WalletTarget.get)
  }

  func walletCheckIn() -> Promise<CheckInResponse> {
    return cnProvider.request(WalletCheckInTarget.get)
  }

  func checkIn() -> Promise<CheckInResponse> {
    return cnProvider.request(WalletCheckInTarget.getNoAuth)
  }

  func resetWallet() -> Promise<Void> {
    return cnProvider.requestVoid(WalletTarget.reset)
  }

}
