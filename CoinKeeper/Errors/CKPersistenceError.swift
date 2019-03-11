//
//  PersistenceError.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CKPersistenceError: Error, LocalizedError {
  case missingValue(key: String)
  case noWallet
  case noUser
  case unexpectedResult
  case failedToFetch(String)

  var errorDescription: String? {
    switch self {
    case .missingValue(let key):  return "Missing value for key: \(key)"
    case .noWallet:               return "Failed to find wallet"
    case .noUser:                 return "Failed to find user"
    case .unexpectedResult:       return "Fetch request returned unexpected result"
    case .failedToFetch(let key): return "Failed to fetch results: \(key)"
    }
  }
}
