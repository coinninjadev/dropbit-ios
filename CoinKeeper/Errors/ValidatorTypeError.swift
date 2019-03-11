//
//  ValidatorTypeError.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol ValidatorTypeError: LocalizedError {
  var debugMessage: String { get }

  /// May be nil if a specific message shouldn't be shown for the exact error.
  var displayMessage: String? { get }
}

extension ValidatorTypeError {
  var errorDescription: String? {
    return debugMessage
  }
}
