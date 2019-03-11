//
//  DatabaseMigrationWorkerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 12/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class DatabaseMigrationWorkerTests: XCTestCase {

  var sut: DatabaseMigrationWorker!

  override func tearDown() {
    sut = nil
  }

  func testMigrateV1toV2() {
    let stack = InMemoryCoreDataStack()
    let context = stack.context

    let migrators = [MockV1toV2()]
    sut = DatabaseMigrationWorker(migrators: migrators)
    _ = sut.migrateIfPossible(in: context)

    migrators.forEach { XCTAssertTrue($0.migrateWasCalled) }
  }

  class MockV1toV2: Migratable {
    var migrateWasCalled = false
    func migrate() {
      migrateWasCalled = true
    }
  }

}
