//
//  BTCMainnetCoin.swift
//  DropBit
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit

class BTCMainnetCoin: CNBBaseCoin {
  init(purpose: CoinDerivation) {
    super.init(purpose: purpose, coin: CoinType.MainNet, account: 0)
  }

  override init(purpose: CoinDerivation, coin: CoinType, account: UInt, networkURL: String?) {
    super.init(purpose: purpose, coin: coin, account: account, networkURL: networkURL)
  }
}
