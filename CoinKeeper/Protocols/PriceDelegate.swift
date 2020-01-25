//
//  PriceDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol PriceDelegate {
  func viewControllerDidRequestPriceDataFor(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
}
