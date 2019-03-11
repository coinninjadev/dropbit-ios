//
//  PinValidationError.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum PinValidationError: Error {
  case incorrectPin(message: String)
}
