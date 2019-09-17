//
//  NetworkManager+LightningRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol LightningRequestable: AnyObject {
  func getOrCreateLightningAccount() -> Promise<LNAccountResponse>
  func createLightningPaymentRequest(sats: Int, expires: Int?, memo: String?) -> Promise<LNCreatePaymentRequestResponse>
  func decodeLightningPaymentRequest(_ request: String) -> Promise<LNDecodePaymentRequestResponse>
  func getLightningLedger() -> Promise<LNLedgerResponse>
  func payLightningPaymentRequest(_ request: String, sats: Int) -> Promise<LNTransactionResponse>
  func withdrawLightningFunds(to address: String, sats: Int) -> Promise<LNTransactionResponse>
  func estimateLightningWithdrawlFees(to address: String, sats: Int) -> Promise<LNTransactionResponse>
}

extension NetworkManager: LightningRequestable {

  func getOrCreateLightningAccount() -> Promise<LNAccountResponse> {
    return Promise.value(LNAccountResponse.emptyInstance)
    //TODO:  return cnProvider.request(LNAccountTarget.get)
  }

  func createLightningPaymentRequest(sats: Int, expires: Int?, memo: String?) -> Promise<LNCreatePaymentRequestResponse> {
    let body = LNCreatePaymentRequestBody(value: sats, expires: expires, memo: memo)
    return cnProvider.request(LNCreatePaymentRequestTarget.create(body))
  }

  func decodeLightningPaymentRequest(_ request: String) -> Promise<LNDecodePaymentRequestResponse> {
    let body = LNDecodePaymentRequestBody(request: request)
    return cnProvider.request(LNDecodePaymentRequestTarget.decode(body))
  }

  func getLightningLedger() -> Promise<LNLedgerResponse> {
    return Promise.value(LNLedgerResponse.emptyInstance)
    //TODO:  return cnProvider.request(LNLedgerTarget.get)
  }

  func payLightningPaymentRequest(_ request: String, sats: Int) -> Promise<LNTransactionResponse> {
    let body = LNPayBody(request: request, value: sats)
    return cnProvider.request(LNTransactionTarget.pay(body))
  }

  func withdrawLightningFunds(to address: String, sats: Int) -> Promise<LNTransactionResponse> {
    return withdrawLightningFunds(with: LNWithdrawBody(address: address, value: sats, blocks: 1, estimate: false))
  }

  func estimateLightningWithdrawlFees(to address: String, sats: Int) -> Promise<LNTransactionResponse> {
    return withdrawLightningFunds(with: LNWithdrawBody(address: address, value: sats, blocks: 1, estimate: true))
  }

  private func withdrawLightningFunds(with body: LNWithdrawBody) -> Promise<LNTransactionResponse> {
    return cnProvider.request(LNTransactionTarget.withdraw(body))
  }
}
