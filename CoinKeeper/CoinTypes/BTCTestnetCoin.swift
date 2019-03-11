//
//  BTCTestnetCoin.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit

class BTCTestnetCoin: CNBBaseCoin {
  override init() {
    super.init(purpose: CoinDerivation.BIP49, coin: CoinType.TestNet, account: 0, networkURL: "tcp://testnet3.libbitcoin.net:19091")
  }
}
