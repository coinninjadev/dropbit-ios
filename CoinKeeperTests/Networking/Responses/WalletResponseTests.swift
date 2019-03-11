//
//  WalletResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class WalletResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = WalletResponse

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

extension WalletResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> WalletResponse {
    return WalletResponse(id: "",
                          publicKeyString: "",
                          createdAt: self.createdAt,
                          updatedAt: self.updatedAt,
                          userId: self.userId)
  }
}
