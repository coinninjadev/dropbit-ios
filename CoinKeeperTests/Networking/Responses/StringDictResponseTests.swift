//
//  StringDictResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class StringDictResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = StringDictResponse

  func testDecodingResponse() {
    let response = decodedSampleJSON()
    XCTAssertNotNil(response, decodingFailureMessage)
  }

  func testEmptyStringThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    // This response doesn't have any required strings
    XCTAssertNoThrow(try sample.copyWithEmptyRequiredStrings().validateStringValues(), emptyStringNoThrowMessage)
  }
}

extension Dictionary: EmptyStringCopyable where Key == String, Value == String {
  func copyWithEmptyRequiredStrings() -> [Key: Value] {
    return self.mapValues { _ in "" }
  }
}
