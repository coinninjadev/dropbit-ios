//
//  BTCTestnetCoin.swift
//  DropBit
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Cnlib

class BTCTestnetCoin: BaseCoin {
  init(purpose: CoinPurpose) {
    super.init(purpose: purpose, coinType: .testnet)
  }
}
