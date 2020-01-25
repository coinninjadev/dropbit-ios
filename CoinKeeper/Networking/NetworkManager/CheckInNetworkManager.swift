//
//  CheckInNetworkManager.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/23/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol WalletCheckInRequestable: AnyObject {
  func walletCheckIn() -> Promise<CheckInResponse>
  func checkIn() -> Promise<CheckInResponse>
}

class CheckInNetworkManager: WalletCheckInRequestable {

  private(set) var cnProvider: CoinNinjaProviderType

  init(coinNinjaProvider: CoinNinjaProviderType = CoinNinjaProvider()) {
    cnProvider = coinNinjaProvider
  }

  func walletCheckIn() -> Promise<CheckInResponse> {
    return cnProvider.request(WalletCheckInTarget.get)
  }

  func checkIn() -> Promise<CheckInResponse> {
    return cnProvider.request(WalletCheckInTarget.getNoAuth)
  }

}
