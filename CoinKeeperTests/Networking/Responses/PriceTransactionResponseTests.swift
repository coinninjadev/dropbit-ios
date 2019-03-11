//
//  PriceTransactionResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class PriceTransactionResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = PriceTransactionResponse

  func testDecodingResponse() {
    let response = decodedSampleJSON()
    XCTAssertNotNil(response, decodingFailureMessage)
  }

  func testNegativePriceThrowsError() {
    let response = PriceTransactionResponse(average: -1)

    XCTAssertThrowsError(try PriceTransactionResponse.validateResponse(response), "Negative price should throw error", { error in
      if let networkError = error as? CKNetworkError,
        case let .invalidValue(keyPath, value, _) = networkError {
        XCTAssertEqual(keyPath, PriceTransactionResponseKey.average.path, "Incorrect key description")
        XCTAssertEqual(value, "-1.0", "Incorrect value description")
      } else {
        XCTFail("Negative price threw incorrect error type")
      }
    })
  }

  func testZeroPriceThrowsError() {
    let response = PriceTransactionResponse(average: 0)

    XCTAssertThrowsError(try PriceTransactionResponse.validateResponse(response), "Zero price should throw error", { _ in })
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

extension PriceTransactionResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> PriceTransactionResponse {
    return PriceTransactionResponse(average: self.average)
  }
}
