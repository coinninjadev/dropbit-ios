//
//  GetBitcoinPage.swift
//  CoinKeeper
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class GetBitcoinPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .getBitcoin(.page), assertionWait: .default, ifExists: ifExists)
  }

}
