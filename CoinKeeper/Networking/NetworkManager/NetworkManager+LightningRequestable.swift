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
  func getLightningLedger(parameters: LNLedgerUrlParameters) -> Promise<LNLedgerResponse>
  func payLightningPaymentRequest(_ request: String, sats: Int) -> Promise<LNTransactionResponse>
  func preauthorizeLightningPayment(sats: Int, encodedPayload: String) -> Promise<LNTransactionResponse>
  func cancelPreauthorizedLightningPayment(withId id: String) -> Promise<LNTransactionResponse>
  func withdrawLightningFunds(to address: String, sats: Int) -> Promise<LNTransactionResponse>
  func estimateLightningWithdrawalFees(to address: String, sats: Int) -> Promise<LNTransactionResponse>
  func withdrawMaxLightningAmountEstimate(to address: String) -> Promise<LNTransactionResponse>
}

extension NetworkManager: LightningRequestable {

  func getOrCreateLightningAccount() -> Promise<LNAccountResponse> {
    return cnProvider.request(LNAccountTarget.get)
  }

  func createLightningPaymentRequest(sats: Int, expires: Int?, memo: String?) -> Promise<LNCreatePaymentRequestResponse> {
    let body = LNCreatePaymentRequestBody(value: sats, expires: expires, memo: memo)
    return cnProvider.request(LNCreatePaymentRequestTarget.create(body))
  }

  func getLightningLedger(parameters: LNLedgerUrlParameters) -> Promise<LNLedgerResponse> {
    return cnProvider.request(LNLedgerTarget.get(parameters))
  }

  func payLightningPaymentRequest(_ request: String, sats: Int) -> Promise<LNTransactionResponse> {
    let body = LNPayBody(request: request, value: sats)
    return cnProvider.request(LNTransactionTarget.pay(body))
      .recover { (error: Error) -> Promise<LNTransactionResponse> in
        self.analyticsManager.track(event: .paymentToInvoiceFailed, with: nil)
        throw error
    }
  }

  func preauthorizeLightningPayment(sats: Int, encodedPayload: String) -> Promise<LNTransactionResponse> {
    let body = LNCreatePaymentRequestBody(value: sats, expires: nil, memo: encodedPayload)
    return cnProvider.request(LNTransactionTarget.preauth(body))
  }

  func cancelPreauthorizedLightningPayment(withId id: String) -> Promise<LNTransactionResponse> {
    return cnProvider.request(LNTransactionTarget.cancelPreauth(id))
  }

  func withdrawLightningFunds(to address: String, sats: Int) -> Promise<LNTransactionResponse> {
    return withdrawLightningFunds(with: LNWithdrawBody(address: address, value: sats, blocks: 1, estimate: false))
  }

  func estimateLightningWithdrawalFees(to address: String, sats: Int) -> Promise<LNTransactionResponse> {
    return withdrawLightningFunds(with: LNWithdrawBody(address: address, value: sats, blocks: 1, estimate: true))
  }

  func withdrawMaxLightningAmountEstimate(to address: String) -> Promise<LNTransactionResponse> {
    return withdrawLightningFunds(with: LNWithdrawBody(address: address, value: -1, blocks: 1, estimate: true))
  }

  private func withdrawLightningFunds(with body: LNWithdrawBody) -> Promise<LNTransactionResponse> {
    return cnProvider.request(LNTransactionTarget.withdraw(body))
  }
}
