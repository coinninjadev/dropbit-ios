//
//  AddressTransactionSummaryResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class AddressTransactionSummaryResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = AddressTransactionSummaryResponse

  func testDecodingJSONProducesTxid() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let expectedTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"
    XCTAssertEqual(response.txid, expectedTxid)
  }

  func testDecodingJSONProducesAddress() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let expectedAddress = "1Gy2Ast7uT13wQByPKs9Vi9Qj1BVcARgVQ"
    XCTAssertEqual(response.address, expectedAddress)
  }

  func testDecodingJSONProducesVin() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let expectedVin = 2058617
    XCTAssertEqual(response.vin, expectedVin)
  }

  func testDecodingJSONProducesVout() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let expectedVout = 0
    XCTAssertEqual(response.vout, expectedVout)
  }

  func testInvalidValuesThrowError() {
    let invalidVinResponse = AddressTransactionSummaryResponse(txid: "", address: "", vin: -1, vout: 1)
    XCTAssertThrowsError(try AddressTransactionSummaryResponse.validateResponse(invalidVinResponse), "Negative vin should throw error", { _ in })

    let invalidVoutResponse = AddressTransactionSummaryResponse(txid: "", address: "", vin: 1, vout: -1)
    XCTAssertThrowsError(try AddressTransactionSummaryResponse.validateResponse(invalidVoutResponse), "Negative vout should throw error", { _ in })
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

extension AddressTransactionSummaryResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> AddressTransactionSummaryResponse {
    return AddressTransactionSummaryResponse(txid: "", address: "", vin: self.vin, vout: self.vout)
  }
}
