//
//  WalletAddressResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class WalletAddressResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = WalletAddressResponse

  func testDecodingJSONProducesId() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.id, "6d1d7318-81b9-492c-b3f3-9d1b24f91d14", "id should decode properly")
  }

  func testDecodingJSONProducesDates() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let expectedCreatedAt = Date.new(2018, 5, 9, time: 16, 09, 05, timeZone: .utc)

    XCTAssertEqual(
      response.createdAt.timeIntervalSinceReferenceDate,
      expectedCreatedAt.timeIntervalSinceReferenceDate,
      accuracy: 0.001,
      "createdAt should decode properly"
    )

    let expectedUpdatedAt = Date.new(2018, 5, 9, time: 17, 09, 05, timeZone: .utc)

    XCTAssertEqual(
      response.updatedAt.timeIntervalSinceReferenceDate,
      expectedUpdatedAt.timeIntervalSinceReferenceDate,
      accuracy: 0.001,
      "updatedAt should decode properly"
    )
  }

  func testDecodingJSONProducesAddress() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.address, "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw", "address should decode properly")
  }

  func testDecodingJSONProducesWalletId() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.walletId, "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d", "wallet ID should decode properly")
  }

  func testEmptyStringThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertThrowsError(try sample.copyWithEmptyRequiredStrings().validateStringValues(), "Empty strings should throw error", { error in
      guard let networkError = error as? CKNetworkError, case .invalidValue = networkError else {
        XCTFail("Empty string error should be CKNetworkError.invalidValue")
        return
      }
    })
  }

}

extension WalletAddressResponse: EmptyStringCopyable {

  func copyWithEmptyRequiredStrings() -> WalletAddressResponse {
    return WalletAddressResponse(id: "",
                                 createdAt: self.createdAt,
                                 updatedAt: self.updatedAt,
                                 address: "",
                                 addressPubkey: nil,
                                 walletId: "")
  }

}
