//
//  CoinNinjaErrorResponse.swift
//  DropBit
//
//  Created by Ben Winters on 2/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// All errors returned by the Coin Ninja API use this response format
struct CoinNinjaErrorResponse: Codable {
  let status: Int?
  let error: String
  let message: String
}
