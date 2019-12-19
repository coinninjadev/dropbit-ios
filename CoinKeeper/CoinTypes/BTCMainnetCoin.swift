//
//  BTCMainnetCoin.swift
//  DropBit
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Cnlib

class BTCMainnetCoin: CNBCnlibBasecoin {
  init(purpose: Int) {
    super.init()
    self.purpose = purpose
    self.coin = 0
    self.account = 0
  }
}
