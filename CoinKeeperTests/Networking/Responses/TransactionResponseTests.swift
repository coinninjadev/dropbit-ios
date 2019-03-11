//
//  TransactionResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class TransactionResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = TransactionResponse

  func testDecodingJSONProducesProperties() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.txid, "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03")
    XCTAssertEqual(response.blockHash, "0000000000000000007aba266efd9aedfc005b69539bf077d1eaffb4a5fb9272")
    XCTAssertEqual(response.blockheight, 502228)

    let expectedReceivedTime = Date.new(2018, 1, 2, time: 15, 23, 28, timeZone: .utc)
    XCTAssertEqual(response.receivedTime, expectedReceivedTime)

    let expectedDate = Date(timeIntervalSince1970: 1514906608)
    XCTAssertEqual(response.date, expectedDate)

    // Vins
    XCTAssertEqual(response.vinResponses.count, 1)
    XCTAssertEqual(response.vinResponses.first?.currentTxid, response.txid)
    XCTAssertEqual(response.vinResponses.first?.txid, "69151603ebe4192d50c1aaaca4e0ab0ea335184e261376c2eda64c35ce9fd1b5")
    XCTAssertEqual(response.vinResponses.first?.value, 999934902)
    XCTAssertEqual(response.vinResponses.first?.vout, 1)

    // Vouts
    XCTAssertEqual(response.voutResponses.count, 2)

    XCTAssertEqual(response.voutResponses.first?.txid, response.txid)
    XCTAssertEqual(response.voutResponses.first?.n, 0)
    XCTAssertEqual(response.voutResponses.first?.value, 100000000)
    XCTAssertEqual(response.voutResponses.first?.addresses, ["18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"])

    XCTAssertEqual(response.voutResponses.last?.txid, response.txid)
    XCTAssertEqual(response.voutResponses.last?.n, 1)
    XCTAssertEqual(response.voutResponses.last?.value, 899764244)
    XCTAssertEqual(response.voutResponses.last?.addresses, ["3LGC2ejYwgnV5SKz6vX7TjdCkPVifDTSX8"])
  }

  func testDecodingJSONWithZeroBlockheight() {
    let blockheightData = sampleJSON(withBlockheight: 0).data(using: .utf8) ?? Data()

    guard let response = try? TransactionResponse.decoder.decode(TransactionResponse.self, from: blockheightData) else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertNil(response.blockheight, "TransactionResponse.blockheight should replace 0 with nil")
  }

  private func sampleJSON(withBlockheight blockheight: Int) -> String {
    return TransactionResponse.sampleJSON
      .replacingOccurrences(of: "\"blockheight\":502228", with: "\"blockheight\":\(blockheight)")
  }

  func testNegativeVoutValuesThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let response = TransactionResponse(txid: sample.txid, voutResponses: [
      TransactionVoutResponse(txid: nil, n: 0, value: 10, addresses: []),
      TransactionVoutResponse(txid: nil, n: 0, value: -1, addresses: [])
      ])

    XCTAssertThrowsError(try TransactionResponse.validateResponse(response), "Negative vout.value should throw error", { _ in })
  }

  func testNegativeVinValuesThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let negativeVoutIndexResponse = TransactionResponse(txid: sample.txid, vinResponses: [
      TransactionVinResponse(txid: "", vout: -2, value: 1)
      ])

    XCTAssertThrowsError(try TransactionResponse.validateResponse(negativeVoutIndexResponse), "Negative vin.vout index should throw error", { _ in })

    let negativeVinValueResponse = TransactionResponse(txid: sample.txid, vinResponses: [
      TransactionVinResponse(txid: "", vout: 1, value: -2000),
      TransactionVinResponse(txid: "", vout: 1, value: 150)
      ])

    XCTAssertThrowsError(try TransactionResponse.validateResponse(negativeVinValueResponse), "Negative vin.value should throw error", { _ in })
  }

  func testZeroBlockheightThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let validResponse = TransactionResponse(txid: sample.txid)
    XCTAssertNoThrow(try TransactionResponse.validateResponse(validResponse), "Validating TransactionResponse should not throw error")

    let invalidResponse = TransactionResponse(txid: sample.txid, blockheight: 0)
    XCTAssertThrowsError(try TransactionResponse.validateResponse(invalidResponse), "0 TransactionResponse.blockheight should throw error", { _ in })
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

extension TransactionResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> TransactionResponse {
    return TransactionResponse(txid: "",
                               blockheight: self.blockheight,
                               vinResponses: self.vinResponses.map { $0.copyWithEmptyRequiredStrings() },
                               voutResponses: self.voutResponses.map { $0.copyWithEmptyRequiredStrings() })
  }
}

extension TransactionVinResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> TransactionVinResponse {
    return TransactionVinResponse(currentTxid: self.currentTxid,
                                  txid: "",
                                  vout: self.vout,
                                  value: self.value,
                                  addresses: self.addresses.map { _ in ""})
  }
}

extension TransactionVoutResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> TransactionVoutResponse {
    return TransactionVoutResponse(txid: self.txid,
                                   n: self.n,
                                   value: self.value,
                                   addresses: self.addresses.map { _ in "" })
  }
}
