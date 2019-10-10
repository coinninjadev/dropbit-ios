//
//  CKWalletError.swift
//  DropBit
//
//  Created by BJ Miller on 9/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CKWalletError: Error, LocalizedError {
  case failedToDeactivate
//  case missingValue(key: String)

  var errorDescription: String? {
    switch self {
    case .failedToDeactivate: return "Failed to deactivate existing wallet."
    }
  }
}
