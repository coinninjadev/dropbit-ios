//
//  WalletFlagsParserTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class WalletFlagsParserTests: XCTestCase {

  func testWalletVersionWithZero() {
    let parser = WalletFlagsParser(flags: 0)
    XCTAssertEqual(parser.flags, 0)
    XCTAssertEqual(parser.walletVersion, WalletFlagsVersion.v0)
    XCTAssertEqual(parser.walletPurpose, WalletFlagsPurpose.BIP49)
    XCTAssertFalse(parser.walletDeactivated)
  }

  func testWalletVersion1() {
    let parser = WalletFlagsParser(flags: 1)
    XCTAssertEqual(parser.flags, 1)
    XCTAssertEqual(parser.walletVersion, WalletFlagsVersion.v1)
    XCTAssertEqual(parser.walletPurpose, WalletFlagsPurpose.BIP49)
    XCTAssertFalse(parser.walletDeactivated)
  }

  func testWalletVersion2() {
    let parser = WalletFlagsParser(flags: 2)
    XCTAssertEqual(parser.flags, 2)
    XCTAssertEqual(parser.walletVersion, WalletFlagsVersion.v2)
    XCTAssertEqual(parser.walletPurpose, WalletFlagsPurpose.BIP49)
    XCTAssertFalse(parser.walletDeactivated)
  }

  func testWalletPurpose84Version1() {
    let parser = WalletFlagsParser(flags: 17)
    XCTAssertEqual(parser.flags, 17)
    XCTAssertEqual(parser.walletVersion, WalletFlagsVersion.v1)
    XCTAssertEqual(parser.walletPurpose, WalletFlagsPurpose.BIP84)
    XCTAssertFalse(parser.walletDeactivated)
  }

  func testWalletDeactivated() {
    let parser = WalletFlagsParser(flags: 0x100)
    XCTAssertEqual(parser.flags, 256)
    XCTAssertEqual(parser.walletVersion, WalletFlagsVersion.v0)
    XCTAssertEqual(parser.walletPurpose, WalletFlagsPurpose.BIP49)
    XCTAssertTrue(parser.walletDeactivated)
  }

  func testSettingVersionV0toV1() {
    let parser = WalletFlagsParser(flags: 0)
    parser.setVersion(.v1)
    XCTAssertEqual(parser.flags, 1)
  }

  func testSettingVersionV1toV2() {
    let parser = WalletFlagsParser(flags: 1)
    parser.setVersion(.v2)
    XCTAssertEqual(parser.flags, 2)
  }

  func testSettingPurpose84V1toV2() {
    let parser = WalletFlagsParser(flags: 0b10001)
    parser.setVersion(.v2)
    XCTAssertEqual(parser.flags, 0b10010)
  }

  func testUpgradingWalletFrom49v1To84v2() {
    let parser = WalletFlagsParser(flags: 0b1)
    parser.setPurpose(.BIP84).setVersion(.v2)
    XCTAssertEqual(parser.flags, 0b10010)
  }

  func testDeactivatingWallet() {
    let parser = WalletFlagsParser(flags: 0b1)
    parser.deactivate()
    XCTAssertEqual(parser.flags, 0b1_0000_0001)
  }

  // backed up
  func testSetBackedUpTrueFromFalse() {
    let parser = WalletFlagsParser(flags: 18) // 0b00010010
    XCTAssertFalse(parser.isWalletBackedUp)
    parser.setBackedUp(true)
    XCTAssertEqual(parser.flags, 0b10_0001_0010)
    XCTAssertTrue(parser.isWalletBackedUp)
  }

  func testSetBackedUpFalseFromTrue() {
    let parser = WalletFlagsParser(flags: 0b10_0001_0010) // 0b00010010
    XCTAssertTrue(parser.isWalletBackedUp)
    parser.setBackedUp(false)
    XCTAssertEqual(parser.flags, 0b00_0001_0010)
    XCTAssertFalse(parser.isWalletBackedUp)
  }

  func testSetBackedUpTrueFromTrue() {
    let parser = WalletFlagsParser(flags: 530) // 0b00010010
    XCTAssertTrue(parser.isWalletBackedUp)
    parser.setBackedUp(true)
    XCTAssertEqual(parser.flags, 0b10_0001_0010)
    XCTAssertTrue(parser.isWalletBackedUp)
  }

  func testSetBackedUpFalseFromFalse() {
    let parser = WalletFlagsParser(flags: 0b1_0010) // 0b00010010
    XCTAssertFalse(parser.isWalletBackedUp)
    parser.setBackedUp(false)
    XCTAssertEqual(parser.flags, 0b1_0010)
    XCTAssertFalse(parser.isWalletBackedUp)
  }

  // has btc balance
  func testSetHasBTCBalanceTrueFromFalse() {
    let parser = WalletFlagsParser(flags: 0b010_0001_0010)
    XCTAssertFalse(parser.hasBTCBalance)
    parser.setHasBTCBalance(true)
    XCTAssertEqual(parser.flags, 0b110_0001_0010)
    XCTAssertTrue(parser.hasBTCBalance)
  }

  func testSetHasBTCBalanceFalseFromTrue() {
    let parser = WalletFlagsParser(flags: 0b110_0001_0010)
    XCTAssertTrue(parser.hasBTCBalance)
    parser.setHasBTCBalance(false)
    XCTAssertEqual(parser.flags, 0b010_0001_0010)
    XCTAssertFalse(parser.hasBTCBalance)
  }

  func testSetHasBTCBalanceTrueFromTrue() {
    let parser = WalletFlagsParser(flags: 0b110_0001_0010)
    XCTAssertTrue(parser.hasBTCBalance)
    parser.setHasBTCBalance(true)
    XCTAssertEqual(parser.flags, 0b110_0001_0010)
    XCTAssertTrue(parser.hasBTCBalance)
  }

  func testSetHasBTCBalanceFalseFromFalse() {
    let parser = WalletFlagsParser(flags: 0b010_0001_0010)
    XCTAssertFalse(parser.hasBTCBalance)
    parser.setHasBTCBalance(false)
    XCTAssertEqual(parser.flags, 0b010_0001_0010)
    XCTAssertFalse(parser.hasBTCBalance)
  }

  // has lightning balance
  func testSetHasLightningBalanceTrueFromFalse() {
    let parser = WalletFlagsParser(flags: 0b0010_0001_0010)
    XCTAssertFalse(parser.hasLightningBalance)
    parser.setHasLightningBalance(true)
    XCTAssertEqual(parser.flags, 0b1010_0001_0010)
    XCTAssertTrue(parser.hasLightningBalance)
  }

  func testSetHasLightningBalanceFalseFromTrue() {
    let parser = WalletFlagsParser(flags: 0b1010_0001_0010)
    XCTAssertTrue(parser.hasLightningBalance)
    parser.setHasLightningBalance(false)
    XCTAssertEqual(parser.flags, 0b0010_0001_0010)
    XCTAssertFalse(parser.hasLightningBalance)
  }

  func testSetHasLightningBalanceTrueFromTrue() {
    let parser = WalletFlagsParser(flags: 0b1010_0001_0010)
    XCTAssertTrue(parser.hasLightningBalance)
    parser.setHasLightningBalance(true)
    XCTAssertEqual(parser.flags, 0b1010_0001_0010)
    XCTAssertTrue(parser.hasLightningBalance)
  }

  func testSetHasLightningBalanceFalseFromFalse() {
    let parser = WalletFlagsParser(flags: 0b0010_0001_0010)
    XCTAssertFalse(parser.hasLightningBalance)
    parser.setHasLightningBalance(false)
    XCTAssertEqual(parser.flags, 0b0010_0001_0010)
    XCTAssertFalse(parser.hasLightningBalance)
  }
}
