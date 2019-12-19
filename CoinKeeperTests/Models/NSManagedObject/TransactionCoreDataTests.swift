//
//  TransactionCoreDataTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData
import Cnlib

class TransactionCoreDataTests: XCTestCase {

  var sut: CKMTransaction!
  var context: NSManagedObjectContext!
  let blockTip = 527444  // 527444 is latest as of 14JUN2018 11:23am

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

  func testTransactionConfigurationFromTransactionResponseProperlyConfiguresTransaction() {
    guard let transactionResponse = try? JSONDecoder().decode(TransactionResponse.self, from: TransactionResponse.sampleData) else {
      XCTFail("should have created a TransactionResponse")
      return
    }

    self.sut = CKMTransaction(insertInto: self.context)
    self.sut.configure(with: transactionResponse, in: self.context, relativeToBlockHeight: blockTip, fullSync: false)
    let expectedConfirmations = 25217

    XCTAssertEqual(self.sut.txid, transactionResponse.txid)
    XCTAssertEqual(self.sut.blockHash, transactionResponse.blockHash)
    XCTAssertEqual(self.sut.confirmations, expectedConfirmations)
    XCTAssertEqual(self.sut.vins.count, 1)
    XCTAssertEqual(self.sut.vouts.count, 2)

    XCTAssertTrue(self.sut.vins.first?.transaction === self.sut)
    let voutsArray = Array(self.sut.vouts)
    XCTAssertTrue(voutsArray.first?.transaction === self.sut)
    XCTAssertTrue(voutsArray.last?.transaction === self.sut)
  }

  // MARK: -
  // MARK: static find methods
  // MARK: Find All
  func testFindAllReturnsAllTransactions() {
    let txids = ["abc123", "def456", "ghi789"]
    let txResponses = txids.map { TransactionResponse(txid: $0) }
    let transactions = txResponses.map { (response: TransactionResponse) -> CKMTransaction in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
      return transaction
    }

    let fetchedTransactions = CKMTransaction.findAll(in: context)

    XCTAssertEqual(transactions.count, fetchedTransactions.count)

    let actualTxids = transactions.map { $0.txid }.sorted()
    let fetchedTxids = fetchedTransactions.map { $0.txid }.sorted()
    XCTAssertEqual(actualTxids, fetchedTxids, "txids should match")
  }

  // MARK: Find All By Txid
  func testFindAllByTxidReturnsOneTransaction() {
    let expectedTxid = "abc123"
    let txidsToInsert = [expectedTxid, "def456", "ghi789"]
    let txResponses = txidsToInsert.map { TransactionResponse(txid: $0) }
    txResponses.forEach { (response: TransactionResponse) in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
    }

    let fetchedTransaction = CKMTransaction.find(byTxid: expectedTxid, in: context)

    XCTAssertNotNil(fetchedTransaction)
    XCTAssertEqual(fetchedTransaction?.txid, expectedTxid)
  }

  func testFindAllByTxidReturnsNil() {
    let badTxid = "foo"
    let txidsToInsert = ["abc123", "def456", "ghi789"]
    let txResponses = txidsToInsert.map { TransactionResponse(txid: $0) }
    txResponses.forEach { (response: TransactionResponse) in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
    }

    let fetchedTransaction = CKMTransaction.find(byTxid: badTxid, in: context)

    XCTAssertNil(fetchedTransaction)
  }

  // MARK: Find All By Txids
  func testFindAllByTxidsReturnsOneTransaction() {
    let expectedTxid = "abc123"
    let txidsToInsert = [expectedTxid, "def456", "ghi789"]
    let txResponses = txidsToInsert.map { TransactionResponse(txid: $0) }
    txResponses.forEach { (response: TransactionResponse) in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
    }

    let fetchedTransactions = CKMTransaction.findAll(byTxids: [expectedTxid], in: context)

    XCTAssertEqual(fetchedTransactions.count, 1, "should return 1 transaction")
    XCTAssertEqual(fetchedTransactions.first?.txid, expectedTxid)
  }

  func testFindAllByTxidsReturnsEmptyArray() {
    let badTxid = "foo"
    let txidsToInsert = ["abc123", "def456", "ghi789"]
    let txResponses = txidsToInsert.map { TransactionResponse(txid: $0) }
    txResponses.forEach { (response: TransactionResponse) in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
    }

    let fetchedTransactions = CKMTransaction.findAll(byTxids: [badTxid], in: context)

    XCTAssertTrue(fetchedTransactions.isEmpty)
  }

  // MARK: Find All Groomable Transactions
  func testFindAllGroomableReturnsNonInvitationAndNonTempTransactions() {
    let expectedTxid = "abc123"
    let txidsToInsert = [expectedTxid, "def456", "ghi789"]
    let txResponses = txidsToInsert.map { TransactionResponse(txid: $0) }
    txResponses.forEach { (response: TransactionResponse) in
      let transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: response, in: context, relativeToBlockHeight: blockTip, fullSync: false)
      if response.txid == "def456" {
        let invitation = CKMInvitation(insertInto: context)
        invitation.id = response.txid
        transaction.invitation = invitation
      } else if response.txid == "ghi789" {
        let tempTx = CKMTemporarySentTransaction(insertInto: context)
        tempTx.amount = 1
        tempTx.feeAmount = 1
        transaction.temporarySentTransaction = tempTx
      }
    }

    let fetchedTransactions = CKMTransaction.findAllGroomable(in: context)

    XCTAssertEqual(fetchedTransactions.count, 1, "should find 1 tx, not with invitation or with temp tx")
    XCTAssertEqual(fetchedTransactions.first?.txid, expectedTxid, "found tx's txid should equal expected txid")

  }

  func testCalculateIsIncoming_IsFalse_WhenFromSameWallet() {
    let vinAddress = receiveAddress(at: 0)
    let voutAddress1 = receiveAddress(at: 1)
    let voutAddress2 = changeAddress(at: 0)
    var transaction: CKMTransaction!
    context.performAndWait {
      let receiveDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 0, in: context)
      let receiveDP1 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 1, in: context)
      let changeDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 1, 0, in: context)
      let vinManagedAddress = CKMAddress.findOrCreate(withAddress: vinAddress, in: context)
      vinManagedAddress.derivativePath = receiveDP0
      let vout1ManagedAddress = CKMAddress.findOrCreate(withAddress: voutAddress1, in: context)
      vout1ManagedAddress.derivativePath = receiveDP1
      let vout2ManagedAddress = CKMAddress.findOrCreate(withAddress: vinAddress, in: context)
      vout2ManagedAddress.derivativePath = changeDP0
      let vinResponse = TransactionVinResponse(currentTxid: "currentTxid", txid: "txid", vout: 0, value: 500_000, addresses: [vinAddress])
      let voutResponse1 = TransactionVoutResponse(txid: "txid", n: 0, value: 400_000, addresses: [voutAddress1])
      let voutResponse2 = TransactionVoutResponse(txid: "txid", n: 1, value: 100_000, addresses: [voutAddress2])

      let txResponse = TransactionResponse(txid: "txid1", vinResponses: [vinResponse], voutResponses: [voutResponse1, voutResponse2])

      transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: txResponse, in: context, relativeToBlockHeight: 500_000, fullSync: false)
    }

    XCTAssertFalse(transaction.isIncoming)
  }

  func testCalculateIsIncoming_IsTrue_WhenFromDifferentWallet() {
    let vinAddress = externalAddress()
    let voutAddress1 = receiveAddress(at: 0)
    let voutAddress2 = externalAddress()
    var transaction: CKMTransaction!
    context.performAndWait {
      let receiveDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 0, in: context)
      let voutManagedAddress1 = CKMAddress.findOrCreate(withAddress: voutAddress1, in: context)
      voutManagedAddress1.derivativePath = receiveDP0
      let vinResponse = TransactionVinResponse(currentTxid: "currentTxid", txid: "txid", vout: 0, value: 500_000, addresses: [vinAddress])
      let voutResponse1 = TransactionVoutResponse(txid: "txid", n: 0, value: 400_000, addresses: [voutAddress1])
      let voutResponse2 = TransactionVoutResponse(txid: "txid", n: 1, value: 100_000, addresses: [voutAddress2])

      let txResponse = TransactionResponse(txid: "txid1", vinResponses: [vinResponse], voutResponses: [voutResponse1, voutResponse2])

      transaction = CKMTransaction(insertInto: context)
      transaction.configure(with: txResponse, in: context, relativeToBlockHeight: 500_000, fullSync: false)
    }

    XCTAssertTrue(transaction.isIncoming)
  }

  func testCalculateIsSentToSelfWithInvitation() {
    var transaction: CKMTransaction!
    context.performAndWait {
      let invitation = CKMInvitation(insertInto: context)
      transaction = CKMTransaction(insertInto: context)
      transaction.invitation = invitation
      transaction.isSentToSelf = true // just to set the opposite value to avoid a false-positive
      transaction.isSentToSelf = transaction.calculateIsSentToSelf(in: context)
    }

    XCTAssertFalse(transaction.isSentToSelf)
  }

  func testCalculateIsSentToSelf_FromDifferentWallet_WithoutInvitation_IsFalse() {
    let vinAddress = externalAddress()
    let voutAddress1 = receiveAddress(at: 0)
    let voutAddress2 = externalAddress()

    var transaction: CKMTransaction!
    context.performAndWait {
      let receiveDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 0, in: context)
      let voutManagedAddress1 = CKMAddress.findOrCreate(withAddress: voutAddress1, in: context)
      voutManagedAddress1.derivativePath = receiveDP0
      let vinResponse = TransactionVinResponse(currentTxid: "currentTxid", txid: "txid", vout: 0, value: 500_000, addresses: [vinAddress])
      let voutResponse1 = TransactionVoutResponse(txid: "txid", n: 0, value: 400_000, addresses: [voutAddress1])
      let voutResponse2 = TransactionVoutResponse(txid: "txid", n: 1, value: 100_000, addresses: [voutAddress2])

      var txResponse = TransactionResponse(txid: "txid1", vinResponses: [vinResponse], voutResponses: [voutResponse1, voutResponse2])
      txResponse.isSentToSelf = false

      transaction = CKMTransaction(insertInto: context)
      transaction.isSentToSelf = true // just to set the opposite value to avoid a false-positive
      transaction.configure(with: txResponse, in: context, relativeToBlockHeight: 500_000, fullSync: false)
      transaction.isSentToSelf = transaction.calculateIsSentToSelf(in: context)
    }

    XCTAssertFalse(transaction.isSentToSelf)
  }

  func testCalculateIsSentToSelf_FromSameWallet_WithoutInvitation_IsTrue() {
    let vinAddress = receiveAddress(at: 0)
    let voutAddress1 = receiveAddress(at: 1)
    let voutAddress2 = changeAddress(at: 0)
    var transaction: CKMTransaction!
    context.performAndWait {
      let receiveDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 0, in: context)
      let receiveDP1 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 0, 1, in: context)
      let changeDP0 = CKMDerivativePath.findOrCreate(with: 49, 0, 0, 1, 0, in: context)
      let vinManagedAddress = CKMAddress.findOrCreate(withAddress: vinAddress, in: context)
      vinManagedAddress.derivativePath = receiveDP0
      let vout1ManagedAddress = CKMAddress.findOrCreate(withAddress: voutAddress1, in: context)
      vout1ManagedAddress.derivativePath = receiveDP1
      let vout2ManagedAddress = CKMAddress.findOrCreate(withAddress: voutAddress2, in: context)
      vout2ManagedAddress.derivativePath = changeDP0
      let vinResponse = TransactionVinResponse(currentTxid: "currentTxid", txid: "txid", vout: 0, value: 500_000, addresses: [vinAddress])
      let voutResponse1 = TransactionVoutResponse(txid: "txid", n: 0, value: 400_000, addresses: [voutAddress1])
      let voutResponse2 = TransactionVoutResponse(txid: "txid", n: 1, value: 100_000, addresses: [voutAddress2])

      let txResponse = TransactionResponse(txid: "txid1", vinResponses: [vinResponse], voutResponses: [voutResponse1, voutResponse2])

      transaction = CKMTransaction(insertInto: context)
      transaction.isSentToSelf = false
      transaction.configure(with: txResponse, in: context, relativeToBlockHeight: 500_000, fullSync: false)
      transaction.isSentToSelf = transaction.calculateIsSentToSelf(in: context)
    }

    XCTAssertTrue(transaction.isSentToSelf)
  }

  private func fakeWords() -> [String] {
    return [
      "enjoy",
      "old",
      "milk",
      "school",
      "vessel",
      "purse",
      "shell",
      "enhance",
      "lens",
      "lemon",
      "master",
      "warfare"
    ]
  }

  private func receiveAddress(at index: Int) -> String {
    let wallet = CNBCnlibNewHDWalletFromWords(fakeWords().joined(separator: " "), BTCMainnetCoin(purpose: 84))!
    let address = try? wallet.receiveAddress(for: index)
    return address?.address ?? ""
  }

  private func changeAddress(at index: Int) -> String {
    let wallet = CNBCnlibNewHDWalletFromWords(fakeWords().joined(separator: " "), BTCMainnetCoin(purpose: 84))!
    let address = try? wallet.changeAddress(for: index)
    return address?.address ?? ""
  }

  private func externalAddress() -> String {
    return "3GPYdoXwWcMokRSoFrPYhauEhPvHxPRLhW"
  }
}
