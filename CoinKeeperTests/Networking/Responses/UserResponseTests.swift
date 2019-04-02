//
//  UserResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class UserResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = UserResponse

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

extension UserResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> UserResponse {
    return UserResponse(id: "",
                        createdAt: self.createdAt,
                        updatedAt: self.updatedAt,
                        status: "",
                        walletId: self.walletId)
  }
}
