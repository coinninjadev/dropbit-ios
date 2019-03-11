//
//  MockNetworkManager+CurrencyValueDataSourceType.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: CurrencyValueDataSourceType {

  func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) {
    latestExchangeRatesWasCalled = true
  }

  func latestFees(responseHandler: (Fees) -> Void) {
    latestFeesWasCalled = true
  }

  func latestFees() -> Promise<Fees> {
    return Promise { _ in }
  }

}
