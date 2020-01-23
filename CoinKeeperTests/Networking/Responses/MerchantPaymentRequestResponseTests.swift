//
//  MerchantPaymentRequestResponseTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class MerchantPaymentRequestResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = MerchantPaymentRequestResponse

  func testEmptyStringThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertThrowsError(try sample.copyWithEmptyRequiredStrings().validateStringValues(), emptyStringTestMessage, { error in
      XCTAssertTrue(error.isNetworkInvalidValueError, emptyStringErrorTypeMessage)
    })
  }

  func testExpiredResponseThrowsError() {

    let expiredDate = Date().addingTimeInterval(-60)
    let expiredResponse = MerchantPaymentRequestResponse.testInstance(expires: expiredDate)

    XCTAssertThrowsError(try MerchantPaymentRequestResponse.validateResponse(expiredResponse),
                         "Soon expired response should throw error", { error in
                          guard let requestError = error as? DBTError.MerchantPaymentRequest, case let .expired(date) = requestError else {
                            XCTFail("Incorrect error type")
                            return
                          }
                          XCTAssertEqual(date, expiredDate, "Expiration date should match")
    })

    let soonExpiredDate = Date().addingTimeInterval(30)
    let soonExpiredResponse = MerchantPaymentRequestResponse.testInstance(expires: soonExpiredDate)

    XCTAssertThrowsError(try MerchantPaymentRequestResponse.validateResponse(soonExpiredResponse),
                         "Soon expired response should throw error", { error in
                          guard let requestError = error as? DBTError.MerchantPaymentRequest, case let .expired(date) = requestError else {
                            XCTFail("Incorrect error type")
                            return
                          }
                          XCTAssertEqual(date, soonExpiredDate, "Expiration date should match")
    })
  }

  func testEmptyOutputsThrowsError() {
    let response = MerchantPaymentRequestResponse.testInstance(output: nil)
    XCTAssertThrowsError(try MerchantPaymentRequestResponse.validateResponse(response),
                         "Empty output response should throw error", { error in
                          guard let requestError = error as? DBTError.MerchantPaymentRequest,
                            case .missingOutput = requestError else {
                              XCTFail("Incorrect error type")
                              return
                          }
    })

  }

  func testBCHCurrencyThrowsError() {
    let invalidCurrency = "BCH"
    let response = MerchantPaymentRequestResponse.testInstance(currency: invalidCurrency)
    XCTAssertThrowsError(try MerchantPaymentRequestResponse.validateResponse(response),
                         "Non-BTC currency should throw error", { error in
                          guard let requestError = error as? DBTError.MerchantPaymentRequest,
                            case let .incorrectCurrency(currency) = requestError else {
                              XCTFail("Incorrect error type")
                              return
                          }
                          XCTAssertEqual(currency, invalidCurrency, "Associated currency should be \(invalidCurrency)")
    })
  }

  func testTestNetworkThrowsError() {
    let invalidNetwork = "test"
    let response = MerchantPaymentRequestResponse.testInstance(network: invalidNetwork)
    XCTAssertThrowsError(try MerchantPaymentRequestResponse.validateResponse(response),
                         "Non-main network should throw error", { error in
                          guard let requestError = error as? DBTError.MerchantPaymentRequest,
                            case let .incorrectNetwork(network) = requestError else {
                              XCTFail("Incorrect error type")
                              return
                          }
                          XCTAssertEqual(network, invalidNetwork, "Associated network should be \(invalidNetwork)")
    })

  }
}

extension MerchantPaymentRequestResponse: EmptyStringCopyable {

  func copyWithEmptyRequiredStrings() -> MerchantPaymentRequestResponse {
    return MerchantPaymentRequestResponse(network: "",
                                          currency: "",
                                          requiredFeeRate: self.requiredFeeRate,
                                          outputs: self.outputs,
                                          time: self.time,
                                          expires: self.expires,
                                          memo: self.memo,
                                          paymentUrl: self.paymentUrl,
                                          paymentId: self.paymentId)
  }

  static func testInstance(network: String = "main",
                           currency: String = "BTC",
                           requiredFeeRate: Double = 20.123,
                           output: MerchantPaymentRequestOutput? = MerchantPaymentRequestOutput.sampleInstance(),
                           time: Date = Date().addingTimeInterval(-2*60),
                           expires: Date = Date().addingTimeInterval(13*60),
                           memo: String? = nil,
                           paymentURL: String = "https://bitpay.com/i/GUGA7vbBSaY9F8YDcGUpQf",
                           paymentId: String = "GUGA7vbBSaY9F8YDcGUpQf") -> MerchantPaymentRequestResponse {

    var outputs: [MerchantPaymentRequestOutput] = []
    if let output = output {
      outputs.append(output)
    }

    return MerchantPaymentRequestResponse(network: network,
                                          currency: currency,
                                          requiredFeeRate: requiredFeeRate,
                                          outputs: outputs,
                                          time: time,
                                          expires: expires,
                                          memo: memo,
                                          paymentUrl: paymentURL,
                                          paymentId: paymentId)
  }

}
