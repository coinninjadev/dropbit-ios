//
//  SetupFlowError.swift
//  DropBit
//
//  Created by BJ Miller on 10/11/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SetupFlowError: Error, LocalizedError {
  case previousPinExistsWhenCreating

  var errorDescription: String? {
    switch self {
    case .previousPinExistsWhenCreating:
      return "Previous PIN exists in Keychain. Cannot create new PIN."
    }
  }
}
