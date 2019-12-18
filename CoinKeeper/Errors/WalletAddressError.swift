//
//  WalletAddressError.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum WalletAddressError: Error, LocalizedError {
  case unexpectedAddress

  var errorDescription: String? {
    switch self {
    case .unexpectedAddress:  return "Address received in response does not match one of the CNBCnlibMetaAddresses provided"
    }
  }
}
