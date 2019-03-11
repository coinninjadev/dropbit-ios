//
//  Applicable.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

protocol Applicable {}

extension Applicable {
  func apply(_ transform: (Self) -> Self) -> Self {
    return transform(self)
  }
}
