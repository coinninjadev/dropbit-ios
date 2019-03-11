//
//  WalletManagerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class WalletManagerTests: XCTestCase {
  var sut: WalletManager!

  override func setUp() {
    super.setUp()
    let words = WalletManager.createMnemonicWords()
    self.sut = WalletManager(words: words)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: initialization
  func testInitializationCreatesWalletWithMnemonicWords() {
    let expectedCount = 12
    XCTAssertEqual(self.sut.mnemonicWords().count, expectedCount, "should contain 12 words")
  }

  // MARK: creating a wallet
  func testCreatingWalletProvidesNewWords() {
    let existingWords = self.sut.mnemonicWords()
    let newWords = WalletManager.createMnemonicWords()
    self.sut.resetWallet(with: newWords)

    XCTAssertNotEqual(self.sut.mnemonicWords(), existingWords, "words should not match")
  }

  func testCreatingWalletWithExistingWords() {
    let existingWords = self.sut.mnemonicWords()
    self.sut.resetWallet(with: TestHelpers.fakeWords())

    XCTAssertEqual(self.sut.mnemonicWords(), TestHelpers.fakeWords(), "words should match")
    XCTAssertNotEqual(self.sut.mnemonicWords(), existingWords, "should not equal previous words")
  }

  // MARK: usable fee rate
  func testFlooredFeeRateAboveMinimumReturnsSameRate() {
    let feeRate: Double = 13
    let expectedFlooredFeeRate: UInt = 13
    let usableFeeRate = self.sut.usableFeeRate(from: feeRate)
    XCTAssertEqual(usableFeeRate, expectedFlooredFeeRate)
  }

  func testNonFlooredFeeRateAboveMinimumReturnsFlooredFeeRate() {
    let feeRate = 13.14159
    let expectedFlooredFeeRate: UInt = 13
    let usableFeeRate = self.sut.usableFeeRate(from: feeRate)
    XCTAssertEqual(usableFeeRate, expectedFlooredFeeRate)
  }

  func testFeeRateBelowMinimumReturnsMinimum() {
    let feeRate = 3.14159
    let expectedFlooredFeeRate: UInt = self.sut.minimumFeeRate
    let usableFeeRate = self.sut.usableFeeRate(from: feeRate)
    XCTAssertEqual(usableFeeRate, expectedFlooredFeeRate)
  }
}
