//
//  NetworkManager+NewsDataRequestable.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import Charts

extension NetworkManager: NewsDataRequestable {
  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]> {
    return newsNetworkManager.requestNewsData(count: count)
  }

  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]> {
    return newsNetworkManager.requestPriceData(period: period)
  }
}
