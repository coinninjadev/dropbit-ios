//
//  VoutCoreDataTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class VoutCoreDataTests: XCTestCase {

  var sut: CKMVout!
  var context: NSManagedObjectContext!

  override func setUp() {
    super.setUp()
    let coreDataStack = InMemoryCoreDataStack()
    self.context = coreDataStack.context
  }

  override func tearDown() {
    self.context = nil
    self.sut = nil
    super.tearDown()
  }

  func testVoutConfigurationFromTransactionVoutResponseProperlyConfiguresVout() {
    guard let transactionResponse = try? JSONDecoder().decode(TransactionResponse.self, from: TransactionResponse.sampleData) else {
      XCTFail("should have created a TransactionResponse")
      return
    }

    guard let voutResponse = transactionResponse.voutResponses.first else {
      XCTFail("should have created a TransactionVoutResponse")
      return
    }

    self.sut = CKMVout(insertInto: self.context)
    self.sut.configure(with: voutResponse, in: self.context)

    XCTAssertEqual(self.sut.addressIDs, voutResponse.addresses)
    XCTAssertEqual(self.sut.amount, voutResponse.value)
    XCTAssertEqual(self.sut.index, voutResponse.n)
  }

  // MARK: find all spendable
  func testFindAllSpendableWithOneSpentOneNotSpentReturnsOneSpendableVout() {
    createVout(with: self.goodVoutResponse(),
               isSpent: false, receiveIndex: 1, confirmations: 1, in: context)

    createVout(with: self.goodVoutResponse2(),
               isSpent: true, receiveIndex: 2, confirmations: 6, in: context)

    let spendableVouts = CKMVout.findAllSpendable(minAmount: 0, in: context)

    XCTAssertEqual(spendableVouts.count, 1, "should have 1 spendable vout")
    XCTAssertEqual(spendableVouts[0].amount, 1, "value should equal spendable vout's value")
  }

  func testFindAllSpendableWithNoneSpendableReturnsNoResults() {
    createVout(with: self.goodVoutResponse(),
               isSpent: true, receiveIndex: 1, confirmations: 1, in: context)

    createVout(with: self.goodVoutResponse2(),
               isSpent: true, receiveIndex: 2, confirmations: 6, in: context)

    let spendableVouts = CKMVout.findAllSpendable(minAmount: 0, in: context)

    XCTAssertTrue(spendableVouts.isEmpty, "should have 0 spendable vouts")
  }

  func testFindAllSpendableWithAllSpendableReturnsAllVouts() {
    createVout(with: self.goodVoutResponse(),
               isSpent: false, receiveIndex: 1, confirmations: 1, in: context)

    createVout(with: self.goodVoutResponse2(),
               isSpent: false, receiveIndex: 2, confirmations: 6, in: context)

    let spendableVouts = CKMVout.findAllSpendable(minAmount: 0, in: context)

    XCTAssertEqual(spendableVouts.count, 2, "should have 2 spendable vouts")
  }

  func testFindAllSpendableExcludesDustVouts() {
    createVout(with: self.goodVoutResponse(),
               isSpent: false, receiveIndex: 1, confirmations: 1, in: context)
    createVout(with: self.dustVoutResponse(),
               isSpent: false, receiveIndex: 1, confirmations: 1, in: context)
    createVout(with: self.notDustVoutResponse(),
               isSpent: false, receiveIndex: 1, confirmations: 1, in: context)

    let dustThreshold = 1000
    let spendableVouts = CKMVout.findAllSpendable(minAmount: dustThreshold, in: context)

    XCTAssertEqual(spendableVouts.count, 1, "should have 1 spendable vouts")
  }

  // MARK: private helpers
  @discardableResult
  private func createVout(with response: TransactionVoutResponse, isSpent: Bool, receiveIndex: Int,
                          confirmations: Int, in context: NSManagedObjectContext) -> CKMVout {
    let tx = CKMTransaction(insertInto: context)
    tx.confirmations = confirmations

    let vout = CKMVout(insertInto: context)
    vout.configure(with: response, in: context)
    vout.transaction = tx
    vout.isSpent = isSpent

    let address = response.addresses.first.flatMap { CKMAddress(address: $0, insertInto: context) }
    address?.derivativePath = CKMDerivativePath.findOrCreate(with: self.receiveDerivativePath(withIndex: receiveIndex), in: context)

    return vout
  }

  private func goodVoutResponse() -> TransactionVoutResponse {
    let json = """
    {
      "value": 1,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 54aac92eb2398146daa547d921ed29a63891a769 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91454aac92eb2398146daa547d921ed29a63891a76988ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"
        ]
      }
    }
    """
    let data = json.data(using: .utf8)!
    //swiftlint:disable:next force_try
    return try! JSONDecoder().decode(TransactionVoutResponse.self, from: data)
  }

  private func goodVoutResponse2() -> TransactionVoutResponse {
    let json = """
    {
      "value": 6082,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_HASH160 4c4e7642d203f5cc412e3e3109606f8b91707190 OP_EQUAL",
        "hex": "a9144c4e7642d203f5cc412e3e3109606f8b9170719087",
        "reqsigs": 1,
        "type": "scripthash",
        "addresses": [
          "38eVGkkoq9LNXZ4SNYUKdX32a9ieTvZ4vd"
        ]
      }
    }
    """
    let data = json.data(using: .utf8)!
    //swiftlint:disable:next force_try
    return try! JSONDecoder().decode(TransactionVoutResponse.self, from: data)
  }

  private func dustVoutResponse() -> TransactionVoutResponse {
    let json = """
    {
      "value": 999,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 54aac92eb2398146daa547d921ed29a63891a769 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91454aac92eb2398146daa547d921ed29a63891a76988ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"
        ]
      }
    }
    """
    let data = json.data(using: .utf8)!
    //swiftlint:disable:next force_try
    return try! JSONDecoder().decode(TransactionVoutResponse.self, from: data)
  }

  private func notDustVoutResponse() -> TransactionVoutResponse {
    let json = """
    {
      "value": 1000,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 54aac92eb2398146daa547d921ed29a63891a769 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91454aac92eb2398146daa547d921ed29a63891a76988ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"
        ]
      }
    }
    """
    let data = json.data(using: .utf8)!
    //swiftlint:disable:next force_try
    return try! JSONDecoder().decode(TransactionVoutResponse.self, from: data)
  }

  private func changeDerivativePath(withIndex i: Int) -> DerivativePathResponse {
    return DerivativePathResponse(purpose: 49, coin: 0, account: 0, change: 1, index: i)
  }

  private func receiveDerivativePath(withIndex i: Int) -> DerivativePathResponse {
    return DerivativePathResponse(purpose: 49, coin: 0, account: 0, change: 0, index: i)
  }

}
