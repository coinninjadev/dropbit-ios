//
//  NSDecimalNumber+Arithmetic.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation


extension NSDecimalNumber {
  static func + (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.adding(right)
  }
}
