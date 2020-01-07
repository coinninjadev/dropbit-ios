//
//  BTCTestnetCoin.swift
//  DropBit
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Cnlib

class BTCTestnetCoin: CNBCnlibBaseCoin {
  init(purpose: Int) {
    super.init()
    self.purpose = purpose
    self.coin = 1
    self.account = 0
  }
}
