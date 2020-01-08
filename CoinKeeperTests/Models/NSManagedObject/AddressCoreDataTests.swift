//
//  AddressCoreDataTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData
import Cnlib

class AddressCoreDataTests: XCTestCase {

  var suts: [CKMAddress] = []
  var context: NSManagedObjectContext!

  override func setUp() {
    super.setUp()
    let stack = InMemoryCoreDataStack()
    context = stack.context
    context.performAndWait {
      self.fakeAddresses().forEach { _ = CKMAddress(address: $0, insertInto: self.context) }
    }
  }

  override func tearDown() {
    self.context = nil
    self.suts = []
    super.tearDown()
  }

  func testAddressObjectsGetCreatedProperly() {
    let count = try? context.count(for: CKMAddress.fetchRequest() as NSFetchRequest<CKMAddress>)
    XCTAssertEqual(count ?? 0, 5)

    do {
      let addresses = try context.fetch(CKMAddress.fetchRequest() as NSFetchRequest<CKMAddress>)
      let addressSet = Set(addresses)
      XCTAssertEqual(addressSet.count, 5, "should have 5 unique addresses")
    } catch {
      XCTFail("error fetching addresses: \(error)")
    }
  }

  // MARK: test derivative path creation and linking
  func testCreateAddressAndDerivativePath() {
    let addressString = fakeAddresses()[0]
    let baseCoin = BTCMainnetCoin(purpose: .nestedSegwit)
    let path = CNBCnlibNewDerivationPath(baseCoin, 0, 0)!
    let address = CKMAddress.findOrCreate(withAddress: addressString, derivativePath: path, in: context)

    XCTAssertEqual(address.derivativePath?.purpose, baseCoin.purpose)
    XCTAssertEqual(address.derivativePath?.coin, baseCoin.coin)
    XCTAssertEqual(address.derivativePath?.account, baseCoin.account)
    XCTAssertEqual(address.derivativePath?.change, path.change)
    XCTAssertEqual(address.derivativePath?.index, path.index)
  }

  // MARK: private methods
  private func fakeAddresses() -> [String] {
    return [
      "38Qg6xV2PfNs87TSEUtTNZEbfVJUvZf3CB",
      "3B7CC5SEVRyqu64ZpyveTkX2wpYxBj4XCS",
      "33E1miGHua8pxLxJbbJrVDyV4irDcjg963",
      "3Ea7BMLiKXqAit9CrtARFgpBoimoxEuDHq",
      "3EQj2VseV2dEpHtXvLtDwZXE7TGs7EVxVw"
    ]
  }
}
