//
//  CoinKeeperContactTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 9/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import Contacts
import PhoneNumberKit

class CoinKeeperContactTests: XCTestCase {
  var sut: CoinKeeperContact!

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testInit() {
    let contact = CNContact()
    let phoneNumber = CNPhoneNumber(stringValue: "937-555-5555")
    sut = CoinKeeperContact(raw: contact, phoneNumber: phoneNumber)
    XCTAssertEqual(sut.kind, .default, "contact kind should be .default")
    XCTAssertEqual(sut.raw, contact, "Contact.raw should equal the contact")
    XCTAssertEqual(sut.countryCode, CountryCode.US, "Should init with default country code of US")
    XCTAssertEqual(sut.phoneNumber, phoneNumber, "phoneNumber should equal input phoneNumber")
    XCTAssertEqual(sut.sanitizedPhoneNumber, "19375555555", "phone number should be sanitized")
    XCTAssertNotEqual(sut.phoneNumberHash, "", "phoneNumberHash should not be empty")
  }

  func testPhoneNumberIsSupported_USWithCountryCode() {
    let contact = CNContact()
    let phoneNumber = CNPhoneNumber(stringValue: "+1 937-555-5555")
    sut = CoinKeeperContact(raw: contact, phoneNumber: phoneNumber)

    let isSupported = self.sut.phoneNumberIsSupported()

    XCTAssertTrue(isSupported, "Phone number should be supported")
  }

  func testPhoneNumberIsSupported_USWithoutCountryCode() {
    let contact = CNContact()
    let phoneNumber = CNPhoneNumber(stringValue: "937-555-5555")
    sut = CoinKeeperContact(raw: contact, phoneNumber: phoneNumber)

    let isSupported = self.sut.phoneNumberIsSupported()

    XCTAssertTrue(isSupported, "Phone number should be supported")
  }

  func testPhoneNumberIsNotSupported_ChinaWithCountryCode() {
    let contact = CNContact()
    let chineseNumber = CNPhoneNumber(stringValue: "+86-21 8888-8888")
    sut = CoinKeeperContact(raw: contact, phoneNumber: chineseNumber)

    let isSupported = self.sut.phoneNumberIsSupported()

    XCTAssertFalse(isSupported, "Phone number should not be supported")
  }

  func testPhoneNumberIsSupported_CanadaWithCountryCode() {
    let contact = CNContact()
    let canadianNumber = CNPhoneNumber(stringValue: "+1 416 555 1212")
    sut = CoinKeeperContact(raw: contact, phoneNumber: canadianNumber)

    let isSupported = self.sut.phoneNumberIsSupported()

    XCTAssertTrue(isSupported, "Phone number should be supported")
  }

  func testPhoneNumberIsSupported_CanadaWithoutCountryCode() {
    let contact = CNContact()
    let canadianNumber = CNPhoneNumber(stringValue: "416 555 1212")
    sut = CoinKeeperContact(raw: contact, phoneNumber: canadianNumber)

    let isSupported = self.sut.phoneNumberIsSupported()

    XCTAssertTrue(isSupported, "Phone number should be supported")
  }

}
