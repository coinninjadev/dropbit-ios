//
//  MockNetworkManager+LightningRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
@testable import DropBit

extension MockNetworkManager: LightningRequestable {

  func getOrCreateLightningAccount() -> Promise<LNAccountResponse> {
    return Promise { _ in }
  }

  func createLightningPaymentRequest(sats: Int, expires: Date, memo: String?) -> Promise<LNCreatePaymentRequestResponse> {
    return Promise { _ in }
  }

  func decodeLightningPaymentRequest(_ request: String) -> Promise<LNDecodePaymentRequestResponse> {
    return Promise { _ in }
  }

  func getLightningLedger() -> Promise<LNLedgerResponse> {
    return Promise { _ in }
  }

  func payLightningPaymentRequest(_ request: String, sats: Int) -> Promise<LNTransactionResponse> {
    return Promise { _ in }
  }

  func withdrawLightningFunds(to address: String, sats: Int, blocks: Int) -> Promise<LNTransactionResponse> {
    return Promise { _ in }
  }

}
