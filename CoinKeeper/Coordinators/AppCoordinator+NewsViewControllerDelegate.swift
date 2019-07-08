//
//  AppCoordinator+NewsViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Charts
import PromiseKit

extension AppCoordinator: NewsViewControllerDelegate {

  func viewControllerDidRequestPriceDataFor(period: PricePeriod) -> Promise<[PriceSummaryResponse]> {
    return networkManager.requestPriceData(period: period)
  }

  func viewControllerDidRequestNewsData(count: Int) -> Promise<[NewsArticleResponse]> {
    return networkManager.requestNewsData(count: count)
  }

}
