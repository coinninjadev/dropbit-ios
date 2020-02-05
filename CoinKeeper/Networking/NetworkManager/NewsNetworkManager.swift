//
//  PriceNetworkManager.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol NewsDataRequestable: AnyObject {
  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]>
  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
}

class NewsNetworkManager: NewsDataRequestable {

  private var cnProvider: CoinNinjaProviderType

  init(coinNinjaProvider: CoinNinjaProviderType) {
    self.cnProvider = coinNinjaProvider
  }

  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]> {
    return cnProvider.requestList(NewsTarget.news(count))
  }

  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]> {
    return cnProvider.requestList(PriceTarget.price(period))
  }

}
