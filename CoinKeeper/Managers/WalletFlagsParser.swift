//
//  WalletFlagsParser.swift
//  DropBit
//
//  Created by BJ Miller on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum WalletFlagsVersion: Int {
  case v0 = 0
  case v1 = 1
  case v2 = 2
}

enum WalletFlagsPurpose: Int {
  case BIP49 = 0
  case BIP84 = 1
}

class WalletFlagsParser {
  static let versionPattern = 0xF     // 0b_0000_0000_0000_1111
  static let versionPatternShift = 0
  static let purposePattern = 0xF0    // 0b_0000_0000_1111_0000
  static let purposePatternShift = 4
  static let deactivatedBit = 0x0100  // 0b_0000_0001_0000_0000

  private(set) var flags: Int

  init(flags: Int) {
    self.flags = flags
  }

  var walletPurpose: WalletFlagsPurpose? {
    let value = (flags & WalletFlagsParser.purposePattern) >> WalletFlagsParser.purposePatternShift
    return WalletFlagsPurpose(rawValue: value)
  }

  var walletVersion: WalletFlagsVersion? {
    let value = (flags & WalletFlagsParser.versionPattern) >> WalletFlagsParser.versionPatternShift
    return WalletFlagsVersion(rawValue: value)
  }

  var walletDeactivated: Bool {
    return (flags & WalletFlagsParser.deactivatedBit) == WalletFlagsParser.deactivatedBit
  }

  @discardableResult
  func setVersion(_ version: WalletFlagsVersion) -> WalletFlagsParser {
    flags = (flags & ~WalletFlagsParser.versionPattern) | (version.rawValue << WalletFlagsParser.versionPatternShift)
    return self
  }

  @discardableResult
  func setPurpose(_ purpose: WalletFlagsPurpose) -> WalletFlagsParser {
    flags = (flags & ~WalletFlagsParser.purposePattern) | (purpose.rawValue << WalletFlagsParser.purposePatternShift)
    return self
  }
}
