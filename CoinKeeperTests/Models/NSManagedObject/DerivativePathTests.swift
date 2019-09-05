//
//  DerivativePathTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 7/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class DerivativePathTests: XCTestCase {

  var context: NSManagedObjectContext!

  override func setUp() {
    super.setUp()

    let stack = InMemoryCoreDataStack()
    context = stack.context
  }

  override func tearDown() {
    context = nil

    super.tearDown()
  }

  // MARK: max receive index
  func testMaxReceiveIndexZeroCorrectlyFetches() {
    let fakePath = CKMDerivativePath(insertInto: context)
    fakePath.purpose = 49
    fakePath.coin = 1
    fakePath.account = 0
    fakePath.change = 0
    fakePath.index = 0
    fakePath.address = CKMAddress(insertInto: context)

    let coin = BTCTestnetCoin(purpose: .BIP49, coin: .TestNet, account: 0, networkURL: nil)
    let maxIndex = CKMDerivativePath.maxUsedReceiveIndex(forCoin: coin, in: context)

    XCTAssertEqual(maxIndex, 0)
  }

  func testMaxReceiveIndexTenCorrectlyFetches() {
    let fakePath = CKMDerivativePath(insertInto: context)
    fakePath.purpose = 49
    fakePath.coin = 1
    fakePath.account = 0
    fakePath.change = 0
    fakePath.index = 10
    fakePath.address = CKMAddress(insertInto: context)

    let coin = BTCTestnetCoin(purpose: .BIP49, coin: .TestNet, account: 0, networkURL: nil)
    let maxIndex = CKMDerivativePath.maxUsedReceiveIndex(forCoin: coin, in: context)

    XCTAssertEqual(maxIndex, 10)
  }

  func testMaxReceiveIndexZeroCorrectlyFetches_ignoresServerAddress() {
    let usedPath = CKMDerivativePath(insertInto: context)
    usedPath.purpose = 49
    usedPath.coin = 1
    usedPath.account = 0
    usedPath.change = 0
    usedPath.index = 0
    usedPath.address = CKMAddress(insertInto: context)

    let serverAddressPath = CKMDerivativePath(insertInto: context)
    serverAddressPath.purpose = 49
    serverAddressPath.coin = 1
    serverAddressPath.account = 0
    serverAddressPath.change = 0
    serverAddressPath.index = 1
    serverAddressPath.serverAddress = CKMServerAddress(insertInto: context)

    let coin = BTCTestnetCoin(purpose: .BIP49, coin: .TestNet, account: 0, networkURL: nil)
    let maxIndex = CKMDerivativePath.maxUsedReceiveIndex(forCoin: coin, in: context)

    XCTAssertEqual(maxIndex, 0)
  }

  // MARK: max change index
  func testMaxChangeIndexZeroCorrectlyFetches() {
    let fakePath = CKMDerivativePath(insertInto: context)
    fakePath.purpose = 49
    fakePath.coin = 1
    fakePath.account = 0
    fakePath.change = 1
    fakePath.index = 0
    fakePath.address = CKMAddress(insertInto: context)

    let coin = BTCTestnetCoin(purpose: .BIP49, coin: .TestNet, account: 0, networkURL: nil)
    let maxIndex = CKMDerivativePath.maxUsedChangeIndex(forCoin: coin, in: context)

    XCTAssertEqual(maxIndex, 0)
  }

  func testMaxChangeIndexTenCorrectlyFetches() {
    let fakePath = CKMDerivativePath(insertInto: context)
    fakePath.purpose = 49
    fakePath.coin = 1
    fakePath.account = 0
    fakePath.change = 1
    fakePath.index = 10
    fakePath.address = CKMAddress(insertInto: context)

    let coin = BTCTestnetCoin(purpose: .BIP49, coin: .TestNet, account: 0, networkURL: nil)
    let maxIndex = CKMDerivativePath.maxUsedChangeIndex(forCoin: coin, in: context)

    XCTAssertEqual(maxIndex, 10)
  }

}
