//
//  BCITransactionResponse.swift
//  CoinKeeper
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// The API offers much more info, but these basics are sufficient for our purposes.
struct BCITransactionResponse: Decodable {

  let hash: String
  let time: Int

}
