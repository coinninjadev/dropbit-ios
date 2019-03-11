//
//  CKDateFormatterTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 7/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
import Foundation
@testable import DropBit

class CKDateFormatterTests: XCTestCase {

  let timeZone = TimeZone(secondsFromGMT: 0)!

  // MARK: RFC3339
  func testRFC3339FormattedDateReturnsDateObject() {
    let dateString = "1996-12-19T16:39:57Z" // rfc3339 date

    let actualDate = CKDateFormatter.rfc3339.date(from: dateString)
    let expectedDate = Date.new(1996, 12, 19, time: 16, 39, 57, 0, timeZone: self.timeZone)

    XCTAssertEqual(actualDate, expectedDate, "actual date should equal expected date")
  }

  func testImproperlyFormattedRFC3339DateReturnsNil() {
    let dateString = "2018-07-02T16:38:21.595153Z" // iso8601 date

    let actualDate = CKDateFormatter.rfc3339.date(from: dateString)

    XCTAssertNil(actualDate, "actual date should be nil")
  }

}
