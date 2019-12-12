//
//  ContactCacheManagerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CoreData

class ContactCacheManagerTests: XCTestCase {

  var sut: ContactCacheManager!

  override func setUp() {
    super.setUp()
    let stackConfig = CoreDataStackConfig(stackType: .contactCache, storeType: .inMemory)
    sut = ContactCacheManager(stackConfig: stackConfig)
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: test things
  func testContactMatchingReturnsObjects() {
    // given
    // set up ccm data
    let rickNumber = "3305551212"
    let rickName = "Rick"
    let mortyNumber = "3305557777"
    let mortyName = "Morty"
    let global1 = GlobalPhoneNumber(countryCode: 1, nationalNumber: rickNumber)
    let global2 = GlobalPhoneNumber(countryCode: 1, nationalNumber: mortyNumber)
    let ccmContext = sut.viewContext
    let ccmPhone1 = CCMPhoneNumber(insertInto: ccmContext)
    let ccmPhone2 = CCMPhoneNumber(insertInto: ccmContext)
    let ccmMetadata1 = CCMValidatedMetadata(phoneNumber: global1, hashedGlobalNumber: "", insertInto: ccmContext)
    let ccmMetadata2 = CCMValidatedMetadata(phoneNumber: global2, hashedGlobalNumber: "", insertInto: ccmContext)
    let ccmContact1 = CCMContact(insertInto: ccmContext)
    let ccmContact2 = CCMContact(insertInto: ccmContext)

    ccmContact1.displayName = rickName
    ccmContact2.displayName = mortyName
    ccmPhone1.cachedValidatedMetadata = ccmMetadata1
    ccmPhone2.cachedValidatedMetadata = ccmMetadata2
    ccmPhone1.cachedContact = ccmContact1
    ccmPhone2.cachedContact = ccmContact2

    // when
    let context = sut.viewContext
    let components = [global1, global2].compactMap { self.sut.managedContactComponents(forGlobalPhoneNumber: $0, in: context) }

    // then
    XCTAssertEqual(components.count, 2)

    let rickComponent = components.first { $0.counterpartyInputs.name == rickName }
    let mortyComponent = components.first { $0.counterpartyInputs.name == mortyName }

    XCTAssertNotNil(rickComponent)
    XCTAssertEqual(rickComponent?.phonenumberInputs.nationalNumber, Int(rickNumber))
    XCTAssertNotNil(mortyComponent)
    XCTAssertEqual(mortyComponent?.phonenumberInputs.nationalNumber, Int(mortyNumber))
  }
}
