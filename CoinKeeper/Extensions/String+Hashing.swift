//
//  String+Hashing.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {

  func sha256() -> String {
    guard let stringData = self.data(using: String.Encoding.utf8) else { return "" }
    return hexStringFromData(input: digest(input: stringData as NSData))
  }

  private func digest(input: NSData) -> NSData {
    let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
    var hash = [UInt8](repeating: 0, count: digestLength)
    CC_SHA256(input.bytes, UInt32(input.length), &hash)
    return NSData(bytes: hash, length: digestLength)
  }

  private func hexStringFromData(input: NSData) -> String {
    var bytes = [UInt8](repeating: 0, count: input.length)
    input.getBytes(&bytes, length: input.length)
    return bytes.reduce("") { $0 + String(format: "%02x", UInt8($1)) }
  }
}
