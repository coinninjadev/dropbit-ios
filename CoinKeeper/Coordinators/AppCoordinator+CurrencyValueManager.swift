//
//  AppCoordinator+CurrencyValueManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

extension AppCoordinator: CurrencyValueDataSourceType {

  func latestExchangeRates(responseHandler: ExchangeRatesRequest) {
    networkManager.latestExchangeRates(responseHandler: responseHandler)
  }

  func latestFees(responseHandler: FeesRequest) {
    networkManager.latestFees(responseHandler: responseHandler)
  }

  func latestFees() -> Promise<Fees> {
    return networkManager.latestFees()
  }

}
