//
//  BTCMainnetCoin.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit

class BTCMainnetCoin: CNBBaseCoin {
  override init() {
    super.init(purpose: CoinDerivation.BIP49, coin: CoinType.MainNet, account: 0, networkURL: "tcp://libbitcoin.coinninja.com:9091")
  }
}
