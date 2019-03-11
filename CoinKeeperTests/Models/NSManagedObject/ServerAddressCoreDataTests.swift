//
//  ServerAddressCoreDataTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class ServerAddressCoreDataTests: XCTestCase {

  var suts: [CKMServerAddress] = []
  var context: NSManagedObjectContext!

  override func setUp() {
    super.setUp()
    let stack = InMemoryCoreDataStack()
    context = stack.context
    self.fakeAddresses().forEach { _ = CKMServerAddress(address: $0, createdAt: Date(), insertInto: self.context) }
  }

  override func tearDown() {
    self.context = nil
    self.suts = []
    super.tearDown()
  }

  func testServerAddressObjectsGetCreatedProperly() {
    let count = try? context.count(for: CKMServerAddress.fetchRequest() as NSFetchRequest<CKMServerAddress>)
    XCTAssertEqual(count ?? 0, 5)

    do {
      let serverAddresses = try context.fetch(CKMServerAddress.fetchRequest() as NSFetchRequest<CKMServerAddress>)
      let addresses = Set(serverAddresses)
      XCTAssertEqual(addresses.count, 5, "should have 5 unique addresses")
    } catch {
      XCTFail("error fetching server addresses: \(error)")
    }
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
