//
//  CKPhoneNumberFormatterTests.swift
//  DropBitTests
//
//  Created by Mitchell on 7/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest
import PhoneNumberKit

class CKPhoneNumberFormatterTests: XCTestCase {

  let kit = PhoneNumberKit()

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testUSPhoneNumberFormatting() {

    let usNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3215551212")
    let expectedNational = "(321) 555-1212"
    let expectedInternational = "+1 321-555-1212"

    let nationalFormatter = CKPhoneNumberFormatter(kit: self.kit, format: .national)
    let nationalFormatted = (try? nationalFormatter.string(from: usNumber)) ?? ""

    let internationalFormatter = CKPhoneNumberFormatter(kit: self.kit, format: .international)
    let internationalFormatted = (try? internationalFormatter.string(from: usNumber)) ?? ""

    XCTAssertEqual(nationalFormatted, expectedNational, "National formats should be equal")
    XCTAssertEqual(internationalFormatted, expectedInternational, "International formats should be equal")
  }

}
