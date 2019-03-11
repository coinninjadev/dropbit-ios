//
//  String+Count.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension String {
  func count(of needle: Character) -> Int {
    return reduce(0) {
      $1 == needle ? $0 + 1 : $0
    }
  }
}
