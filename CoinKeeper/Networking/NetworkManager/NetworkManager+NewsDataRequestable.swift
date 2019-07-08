//
//  NetworkManager+NewsDataRequestable.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import Charts

protocol NewsDataRequestable: AnyObject {
  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]>
  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
}

extension NetworkManager: NewsDataRequestable {
  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]> {
    return cnProvider.requestList(NewsTarget.news(count))
  }
  
  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]> {
    return cnProvider.requestList(PriceTarget.price(period))
  }
}
