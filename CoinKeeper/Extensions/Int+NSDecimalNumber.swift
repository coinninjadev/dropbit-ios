//
//  Int+NSDecimalNumber.swift
//  DropBit
//
//  Created by Mitch on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension Int {

  var asNSDecimalNumber: NSDecimalNumber {
    return NSDecimalNumber(value: self)
  }
}
