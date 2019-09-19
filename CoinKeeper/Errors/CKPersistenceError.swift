//
//  PersistenceError.swift
//  DropBit
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CKPersistenceError: Error, LocalizedError {
  case missingValue(key: String)
  case noWalletWords
  case noManagedWallet
  case noWalletManager
  case noUser
  case phoneNotVerified
  case unexpectedResult
  case failedToFetch(String)
  case keychainWriteFailed(key: String)
  case failedToBatchDeleteWallet([NSError])

  var errorDescription: String? {
    switch self {
    case .missingValue(let key):  return "Missing value for key: \(key)"
    case .noWalletWords:          return "Failed to fetch recovery words from Keychain"
    case .noManagedWallet:        return "Failed to find wallet"
    case .noWalletManager:        return "Wallet manager is nil"
    case .noUser:                 return "Failed to find user"
    case .phoneNotVerified:       return "Phone not verified. Please verify your phone number to send a DropBit."
    case .unexpectedResult:       return "Fetch request returned unexpected result"
    case .failedToFetch(let key): return "Failed to fetch results: \(key)"
    case .keychainWriteFailed(let key): return "Failed to store value in keychain for key: \(key)"
    case .failedToBatchDeleteWallet(let nsErrors):
      var message = "Failed to batch delete wallet. Errors:"
      for nsError in nsErrors {
        message.append("\n\n\t\(nsError.localizedDescription): \(nsError.userInfo)")
      }
      return message
    }
  }
}
