//
//  SubscriptionAvailableTopicResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SubscriptionAvailableTopicResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = SubscriptionAvailableTopicResponse

  func testDecodingSampleJSONProducesCorrectProperties() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.id, "5805b3a0-ed99-4073-ad18-72adff181b9e")
    XCTAssertEqual(response.createdAt, 1531921356)
    XCTAssertEqual(response.updatedAt, 1531921356)
    XCTAssertEqual(response.name, "Max 256 chars")
    XCTAssertEqual(response.displayName, "Max 10 chars, required for SMS")
    XCTAssertEqual(response.description, "Use me in the UI")
  }

  func testEmptyStringThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertThrowsError(try sample.copyWithEmptyRequiredStrings().validateStringValues(), emptyStringTestMessage, { error in
      XCTAssertTrue(error.isNetworkInvalidValueError, emptyStringErrorTypeMessage)
    })
  }

}

extension SubscriptionAvailableTopicResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> SubscriptionAvailableTopicResponse {
    return SubscriptionAvailableTopicResponse(id: "",
                                              createdAt: self.createdAt,
                                              updatedAt: self.updatedAt,
                                              name: "",
                                              displayName: "",
                                              description: "")
  }
}
