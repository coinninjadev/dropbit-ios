//
//  NSDecimalNumber+Comparable.swift
//  DropBit
//
//  Created by Mitchell on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NSDecimalNumber: Comparable {
  static public func == (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedSame
  }

  static public func < (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedAscending
  }
}
