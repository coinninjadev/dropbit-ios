//
//  SpendableBalanceError.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

enum SpendableBalanceError: Error {
  case voutFetchFailed
  case vinFetchFailed
  case contextFailedToSave
}
