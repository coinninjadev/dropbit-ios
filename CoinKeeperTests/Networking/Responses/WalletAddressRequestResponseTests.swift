//
//  WalletAddressRequestResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class WalletAddressRequestResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = WalletAddressRequestResponse

  func testDecodingJSONProducesId() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }
    XCTAssertEqual(response.id, "a1bb1d88-bfc8-4085-8966-e0062278237c", "id should decode properly")
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

    let expectedUpdatedAt = Date.new(2018, 5, 9, time: 16, 11, 05, timeZone: .utc)

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

  func testDecodingJSONProducesStatus() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.status, "new", "status should decode properly")
  }

  // MARK: sample sent data
  func testSentRequestResponsesAreParsedProperly() {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      guard let response = try jsonDecoder
        .decode([WalletAddressRequestResponse].self, from: WalletAddressRequestResponse.sampleSentData())
        .first else {
          XCTFail("failed to decode first WalletAddressRequestResponse")
          return
      }
      XCTAssertEqual(response.id, "a1bb1d88-bfc8-4085-8966-e0062278237c")
      XCTAssertEqual(response.address, "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw")
      XCTAssertEqual(response.status, "new")
      XCTAssertEqual(response.walletId, "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d")
      XCTAssertEqual(response.phoneNumberHash, "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49")
      XCTAssertEqual(response.createdAt.timeIntervalSinceReferenceDate, 1525882145)
    } catch {
      XCTFail("decoding failed")
    }
  }

  func testNilAmountsThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let nilBTCAmount = MetadataAmount(btc: nil, usd: 100)
    let btcResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: nilBTCAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(btcResponse),
                         "WalletAddressRequestResponse with nil btcAmount should throw error", { _ in })

    let nilUSDAmount = MetadataAmount(btc: 100, usd: nil)
    let usdResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: nilUSDAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(usdResponse),
                         "WalletAddressRequestResponse with nil usdAmount should throw error", { _ in })
  }

  func testZeroAmountsThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let zeroBTCAmount = MetadataAmount(btc: 0, usd: 100)
    let btcResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: zeroBTCAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(btcResponse),
                         "WalletAddressRequestResponse with btcAmount == 0 should throw error", { _ in })

    let zeroUSDAmount = MetadataAmount(btc: 100, usd: 0)
    let usdResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: zeroUSDAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(usdResponse),
                         "WalletAddressRequestResponse with usdAmount == 0 should throw error", { _ in })
  }

  func testNegativeAmountsThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let negativeBTCAmount = MetadataAmount(btc: -1, usd: 100)
    let btcResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: negativeBTCAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(btcResponse),
                         "WalletAddressRequestResponse with negative btcAmount should throw error", { _ in })

    let negativeUSDAmount = MetadataAmount(btc: 100, usd: -1)
    let usdResponse = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: negativeUSDAmount,
                                                                             sender: nil,
                                                                             receiver: nil,
                                                                             requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(usdResponse),
                         "WalletAddressRequestResponse with negative usdAmount should throw error", { _ in })
  }

  func testPositiveAmountsDoNotThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let zeroBTCAmount = MetadataAmount(btc: 10_000, usd: 100)
    let response = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: zeroBTCAmount,
                                                                          sender: nil,
                                                                          receiver: nil,
                                                                          requestId: nil))
    XCTAssertNoThrow(try WalletAddressRequestResponse.validateResponse(response),
                     "WalletAddressRequestResponse with positive btcAmount and usdAmount should not throw error")
  }

  func testMaxSatoshiThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let maxBTCAmount = MetadataAmount(btc: MAX_SATOSHI, usd: 100)
    let response = sample.copy(withMetadata: WalletAddressRequestMetadata(amount: maxBTCAmount,
                                                                          sender: nil,
                                                                          receiver: nil,
                                                                          requestId: nil))
    XCTAssertThrowsError(try WalletAddressRequestResponse.validateResponse(response),
                         "WalletAddressRequestResponse with max satoshi amount should throw error", { _ in })
  }

  func testEmptyOptionalStringsConvertToNil() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let response = sample.copyWithEmptyOptionalStrings()
    do {
      let res = try response.validateStringValues()
      XCTAssertNil(res.address, "address should be nil")
      XCTAssertNil(res.txid, "txid should be nil")
      XCTAssertNil(res.phoneNumberHash, "phoneNumberHash should be nil")
      XCTAssertNil(res.status, "status should be nil")
      XCTAssertNil(res.walletId, "walletId should be nil")
    } catch {
      XCTFail("String validation threw error: \(error.localizedDescription)")
    }
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

extension WalletAddressRequestResponse {

  fileprivate func copy(withMetadata metadata: WalletAddressRequestMetadata) -> WalletAddressRequestResponse {
    return WalletAddressRequestResponse(id: self.id,
                                        createdAt: self.createdAt,
                                        updatedAt: self.updatedAt,
                                        address: self.address,
                                        addressPubkey: self.addressPubkey,
                                        txid: self.txid,
                                        metadata: metadata,
                                        phoneNumberHash: self.phoneNumberHash,
                                        status: self.status,
                                        walletId: self.walletId)
  }

  fileprivate func copyWithEmptyOptionalStrings() -> WalletAddressRequestResponse {
    return WalletAddressRequestResponse(id: self.id,
                                        createdAt: self.createdAt,
                                        updatedAt: self.updatedAt,
                                        address: "",
                                        addressPubkey: "",
                                        txid: "",
                                        metadata: self.metadata,
                                        phoneNumberHash: "",
                                        status: "",
                                        walletId: "")
  }

}

extension WalletAddressRequestResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> WalletAddressRequestResponse {
    return WalletAddressRequestResponse(id: "",
                                        createdAt: self.createdAt,
                                        updatedAt: self.updatedAt,
                                        address: self.address,
                                        addressPubkey: self.addressPubkey,
                                        txid: self.txid,
                                        metadata: self.metadata,
                                        phoneNumberHash: self.phoneNumberHash,
                                        status: self.status,
                                        walletId: self.walletId)
  }
}
