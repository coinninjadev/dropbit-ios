//
//  DeviceEndpointResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class DeviceEndpointResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = DeviceEndpointResponse

  func testDecodingResponse() {
    let response = decodedSampleJSON()
    XCTAssertNotNil(response, decodingFailureMessage)
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

extension DeviceEndpointResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> DeviceEndpointResponse {
    return DeviceEndpointResponse(id: "",
                                  createdAt: self.createdAt,
                                  updatedAt: self.updatedAt,
                                  application: self.application,
                                  platform: self.platform,
                                  token: "",
                                  device: self.device,
                                  deviceId: "")
  }
}
