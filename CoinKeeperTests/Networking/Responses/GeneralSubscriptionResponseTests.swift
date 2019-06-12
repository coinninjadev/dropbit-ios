//
//  GeneralSubscriptionResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class GeneralSubscriptionResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = SubscriptionInfoResponse

  func testDecodingSampleJSONProducesCorrectProperties() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.availableTopics.count, 1)
    XCTAssertEqual(response.subscriptions.count, 1)
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

extension SubscriptionInfoResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> SubscriptionInfoResponse {
    return SubscriptionInfoResponse(subscriptions: self.subscriptions, availableTopics: self.availableTopics)
  }
}
