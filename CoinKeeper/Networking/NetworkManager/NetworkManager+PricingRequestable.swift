//
//  NetworkManager+PricingRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol PricingRequestable: AnyObject {
  func fetchDayAveragePrice(for txid: String) -> Promise<PriceTransactionResponse>
}

extension NetworkManager: PricingRequestable {

  func fetchDayAveragePrice(for txid: String) -> Promise<PriceTransactionResponse> {
    return cnProvider.request(PricingTarget.getTxPricing(txid))
  }

}
