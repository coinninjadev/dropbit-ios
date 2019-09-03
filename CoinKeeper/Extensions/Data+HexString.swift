//
//  Data+HexString.swift
//  DropBit
//
//  Created by Mitchell on 5/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension Data {

  var hexString: String {
    let format = "%02hhx"
    return map { String(format: format, $0) }.joined()
  }

  // Convert 0 ... 9, a ... f, A ...F to their decimal value,
  // return nil for all other input characters
  fileprivate func decodeNibble(_ u: UInt16) -> UInt8? {
    switch u {
    case 0x30 ... 0x39:
      return UInt8(u - 0x30)
    case 0x41 ... 0x46:
      return UInt8(u - 0x41 + 10)
    case 0x61 ... 0x66:
      return UInt8(u - 0x61 + 10)
    default:
      return nil
    }
  }

  init?(fromHexEncodedString string: String) {
    var str = string
    if str.count % 2 != 0 {
      // insert 0 to get even number of chars
      str.insert("0", at: str.startIndex)
    }

    let utf16 = str.utf16
    self.init(capacity: utf16.count / 2)

    var index = utf16.startIndex
    while index != str.utf16.endIndex {
      guard let hi = decodeNibble(utf16[index]),
        let loIndex = utf16.index(index, offsetBy: 1, limitedBy: utf16.endIndex),
        let lo = decodeNibble(utf16[loIndex]) else {
          return nil
      }
      var value = hi << 4 + lo
      self.append(&value, count: 1)
      index = utf16.index(index, offsetBy: 2, limitedBy: utf16.endIndex)!
    }
  }
}
