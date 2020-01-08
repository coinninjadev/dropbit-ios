//
//  BaseCoin.swift
//  DropBit
//
//  Created by BJ Miller on 1/8/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Cnlib

enum CoinPurpose: Int {
  case nestedSegwit = 49
  case segwit = 84
}

enum CoinType: Int {
  case mainnet, testnet
}

class BaseCoin: CNBCnlibBaseCoin {
  init(purpose: CoinPurpose, coinType: CoinType) {
    super.init(purpose.rawValue, coin: coinType.rawValue, account: 0)!
  }
}
