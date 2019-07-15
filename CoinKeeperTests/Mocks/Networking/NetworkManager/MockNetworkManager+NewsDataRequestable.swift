//
//  MockNetworkManager+NewsDataRequestable.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 7/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit
import CoreData
import OAuthSwift

extension MockNetworkManager: NewsDataRequestable {
  func requestNewsData(count: Int) -> Promise<[NewsArticleResponse]> {
    return Promise { _ in }
  }

  func requestPriceData(period: PricePeriod) -> Promise<[PriceSummaryResponse]> {
    return Promise { _ in }
  }

}
