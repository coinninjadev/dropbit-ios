//
//  NSAttributedString+Concatenate.swift
//  DropBit
//
//  Created by Mitch on 1/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension NSAttributedString {
  static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return result
  }

  static func + (left: NSAttributedString, right: String) -> NSAttributedString {
    let rightAttributedString = NSAttributedString(string: right)

    let result = NSMutableAttributedString()
    result.append(left)
    result.append(rightAttributedString)
    return result
  }
}
