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
  static let deactivatedBitShift = 8
  static let hasBackedUpBit = 0x0200  // 0b_0000_0010_0000_0000
  static let hasBackedUpBitShift = 9
  static let hasBTCBalanceBit = 0x0400  // 0b_0000_0100_0000_0000
  static let hasBTCBalanceBitShift = 10
  static let hasLightningBalanceBit = 0x0800  // 0b_0000_1000_0000_0000
  static let hasLightningBalanceBitShift = 11

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

  @discardableResult
  func deactivate() -> WalletFlagsParser {
    flags = flags | (1 << WalletFlagsParser.deactivatedBitShift)
    return self
  }

  @discardableResult
  func setBackedUp(_ backedUp: Bool) -> WalletFlagsParser {
    let newVal = backedUp ? 1 : 0
    flags = (flags & ~WalletFlagsParser.hasBackedUpBit) | (newVal << WalletFlagsParser.hasBackedUpBitShift)
    return self
  }

  var isWalletBackedUp: Bool {
    return (flags >> WalletFlagsParser.hasBackedUpBitShift) == 1
  }

  @discardableResult
  func setHasBTCBalance(_ hasBalance: Bool) -> WalletFlagsParser {
    let newVal = hasBalance ? 1 : 0
    flags = (flags & ~WalletFlagsParser.hasBTCBalanceBit) | (newVal << WalletFlagsParser.hasBTCBalanceBitShift)
    return self
  }

  var hasBTCBalance: Bool {
    return (flags >> WalletFlagsParser.hasBTCBalanceBitShift) == 1
  }

  @discardableResult
  func setHasLightningBalance(_ hasBalance: Bool) -> WalletFlagsParser {
    let newVal = hasBalance ? 1 : 0
    flags = (flags & ~WalletFlagsParser.hasLightningBalanceBit) | (newVal << WalletFlagsParser.hasLightningBalanceBitShift)
    return self
  }

  var hasLightningBalance: Bool {
    return (flags >> WalletFlagsParser.hasLightningBalanceBitShift) == 1
  }
}
