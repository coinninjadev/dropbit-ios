//
//  CKMPhoneNumberTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class CKMPhoneNumberTests: XCTestCase {

  var stack: InMemoryCoreDataStack!
  var context: NSManagedObjectContext!

  override func setUp() {
    super.setUp()
    stack = InMemoryCoreDataStack()
    context = stack.context
  }

  override func tearDown() {
    context = nil
    stack = nil
    super.tearDown()
  }

  func testFindAllPhoneNumbers_WithoutCounterparty_ReturnsItemsWithoutRelationship() {
    // given
    let globalPhone1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let globalPhone2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305557777")
    let phone1 = CKMPhoneNumber(phoneNumber: globalPhone1, insertInto: context)
    _ = CKMPhoneNumber(phoneNumber: globalPhone2, insertInto: context)

    let expectedName = "Alice"
    let counterparty = CKMCounterparty(name: expectedName, insertInto: context)
    phone1?.counterparty = counterparty
    _ = phone1.map { counterparty.phoneNumbers.insert($0) }

    // when
    let found = CKMPhoneNumber.findAllWithoutCounterpartyName(in: context)

    // then
    XCTAssertEqual(found.count, 1)
    XCTAssertNil(found.first?.counterparty)
  }

  func testFindAllPhoneNumbers_WithNoUnnamedPhoneNumbers_ReturnsEmptyArray() {
    // given
    let globalPhone1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let globalPhone2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305557777")
    let phone1 = CKMPhoneNumber(phoneNumber: globalPhone1, insertInto: context)
    let phone2 = CKMPhoneNumber(phoneNumber: globalPhone2, insertInto: context)

    let expectedName1 = "Alice"
    let expectedName2 = "Bob"
    let counterparty1 = CKMCounterparty(name: expectedName1, insertInto: context)
    phone1?.counterparty = counterparty1
    _ = phone1.map { counterparty1.phoneNumbers.insert($0) }
    let counterparty2 = CKMCounterparty(name: expectedName2, insertInto: context)
    phone2?.counterparty = counterparty2
    _ = phone2.map { counterparty2.phoneNumbers.insert($0) }

    // when
    let found = CKMPhoneNumber.findAllWithoutCounterpartyName(in: context)

    // then
    XCTAssertEqual(found.count, 0)
  }

  func testFindAllPhoneNumbers_WithAllUnnamedPhoneNumbers_ReturnsArrayOfAll() {
    // given
    let globalPhone1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let globalPhone2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305557777")
    _ = CKMPhoneNumber(phoneNumber: globalPhone1, insertInto: context)
    _ = CKMPhoneNumber(phoneNumber: globalPhone2, insertInto: context)

    // when
    let found = CKMPhoneNumber.findAllWithoutCounterpartyName(in: context)

    // then
    XCTAssertEqual(found.count, 2)
    XCTAssertNil(found.first?.counterparty)
    XCTAssertNil(found.last?.counterparty)
  }

}
