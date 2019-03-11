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
import CNBitcoinKit

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
    let path = CNBDerivationPath(purpose: .BIP49, coinType: .MainNet, account: 0, change: 0, index: 0)
    let address = CKMAddress.findOrCreate(withAddress: addressString, derivativePath: path, in: context)

    XCTAssertEqual(address.derivativePath?.purpose, Int(path.purposeValue()))
    XCTAssertEqual(address.derivativePath?.coin, Int(path.coinValue()))
    XCTAssertEqual(address.derivativePath?.account, Int(path.account))
    XCTAssertEqual(address.derivativePath?.change, Int(path.change))
    XCTAssertEqual(address.derivativePath?.index, Int(path.index))
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
