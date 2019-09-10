//
//  VinCoreDataTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class VinCoreDataTests: XCTestCase {

  var sut: CKMVin!
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

  func testVinConfigurationFromTransactionVinResponseProperlyConfiguresVin() {
    guard let transactionResponse = try? JSONDecoder().decode(TransactionResponse.self, from: TransactionResponse.sampleData) else {
      XCTFail("should have created a TransactionResponse")
      return
    }

    guard let vinResponse = transactionResponse.vinResponses.first else {
      XCTFail("should have created a TransactionVinResponse")
      return
    }

    self.context.performAndWait {
      self.sut = CKMVin.findOrCreate(with: vinResponse, in: context, fullSync: false)
    }

    XCTAssertEqual(self.sut.addressIDs, vinResponse.addresses)
    XCTAssertEqual(self.sut.amount, vinResponse.value)
    XCTAssertEqual(self.sut.previousTxid, vinResponse.txid)
    XCTAssertEqual(self.sut.previousVoutIndex, vinResponse.vout)
  }

}
