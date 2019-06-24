//
//  CheckInBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CheckInBroker: CKPersistenceBroker, CheckInBrokerType {

  var cachedBTCUSDRate: Double {
    get { return userDefaultsManager.double(for: .exchangeRateBTCUSD) }
    set { userDefaultsManager.set(newValue, for: .exchangeRateBTCUSD) }
  }

  var cachedBlockHeight: Int {
    get { return userDefaultsManager.integer(for: .blockheight) }
    set { userDefaultsManager.set(newValue, for: .blockheight) }
  }

  var cachedBestFee: Double {
    get { return userDefaultsManager.double(for: .feeBest) }
    set { userDefaultsManager.set(newValue, for: .feeBest) }
  }

  var cachedBetterFee: Double {
    get { return userDefaultsManager.double(for: .feeBetter) }
    set { userDefaultsManager.set(newValue, for: .feeBetter) }
  }

  var cachedGoodFee: Double {
    get { return userDefaultsManager.double(for: .feeGood) }
    set { userDefaultsManager.set(newValue, for: .feeGood) }
  }

}
