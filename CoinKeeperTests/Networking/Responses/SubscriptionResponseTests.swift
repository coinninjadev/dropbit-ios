//
//  SubscriptionResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SubscriptionResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = SubscriptionResponse

  func testDecodingSampleJSONProducesCorrectProperties() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.id, "752c6358-d746-4d26-90ec-9f5f2d72d438")
    XCTAssertEqual(response.createdAt, 1531921356)
    XCTAssertEqual(response.updatedAt, 1531921356)
    XCTAssertEqual(response.ownerType, "Wallet")
    XCTAssertEqual(response.ownerTypeCase, .wallet)
    XCTAssertEqual(response.deviceEndpoint.id, "5805b3a0-ed99-4073-ad18-72adff181b9e", "nested DeviceEndpointResponse type should decode")
    XCTAssertEqual(response.deviceEndpointId, "5805b3a0-ed99-4073-ad18-72adff181b9e")
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

extension SubscriptionResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> SubscriptionResponse {
    return SubscriptionResponse(id: "",
                                createdAt: self.createdAt,
                                updatedAt: self.updatedAt,
                                ownerType: "",
                                ownerId: "",
                                deviceEndpoint: self.deviceEndpoint,
                                deviceEndpointId: "")
  }
}
