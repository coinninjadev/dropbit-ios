//
//  CheckInResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class CheckInResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = CheckInResponse

  // MARK: with max/avg/min fee structure
  func testDecodingJSONProducesBlockheight() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }
    XCTAssertEqual(response.blockheight, 518631, "blockheight should decode properly")
  }

  func testDecodingJSONProducesAllFeesDataWithMaxData() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.fees.best, 347.222, "best should decode properly")
    XCTAssertEqual(response.fees.better, 12.425, "better should decode properly")
    XCTAssertEqual(response.fees.good, 0.98785, "good should decode properly")
  }

  func testDecodingJSONProducesLastPrice() {
    guard let response = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(response.pricing.last, 6496.79, "pricing.last should decode properly")
  }

  func testDecodingInvalidPriceThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let negativeCheckIn = checkIn(withPricing: PriceResponse(last: -1), sample: sample)

    XCTAssertThrowsError(try CheckInResponse.validateResponse(negativeCheckIn), "Negative price should throw error", { error in
      if let networkError = error as? CKNetworkError,
        case let .invalidValue(keyPath, value, _) = networkError {
        XCTAssertEqual(keyPath, PriceResponseKey.last.path, "Incorrect key description")
        XCTAssertEqual(value, "-1.0", "Incorrect value description")
      } else {
        XCTFail("Negative price threw incorrect error type")
      }
    })

    let zeroCheckIn = checkIn(withPricing: PriceResponse(last: 0), sample: sample)

    XCTAssertThrowsError(try CheckInResponse.validateResponse(zeroCheckIn),
                         "Zero price should throw error", { error in
                          if let networkError = error as? CKNetworkError {
                            let errorDesc = networkError.errorDescription ?? "-"
                            print("Identified sample price of 0 as invalid: \(errorDesc)")
                          }
    })
  }

  func testDecodingInvalidFeesThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    // Test negative values for all fees, first one also checks error values

    let negativeFee: Double = -10
    let excessiveFee = FeesResponse.validFeeCeiling + 1

    let maxCheckIn = checkIn(withFees: generateFeesResponse(max: negativeFee), sample: sample)

    XCTAssertThrowsError(try CheckInResponse.validateResponse(maxCheckIn),
                         "Negative max fee should throw error", { error in
                          if let networkError = error as? CKNetworkError,
                            case let .invalidValue(keyPath, value, _) = networkError {
                            XCTAssertEqual(keyPath, FeesResponseKey.max.path, "Incorrect key description")
                            XCTAssertEqual(value, "-10.0", "Incorrect value description")
                          } else {
                            XCTFail("Negative fee threw incorrect error type")
                          }
    })

    let avgCheckIn = checkIn(withFees: generateFeesResponse(avg: negativeFee), sample: sample)
    XCTAssertThrowsError(try CheckInResponse.validateResponse(avgCheckIn), "Negative avg fee should throw error", { _ in })

    let minCheckIn = checkIn(withFees: generateFeesResponse(min: negativeFee), sample: sample)
    XCTAssertThrowsError(try CheckInResponse.validateResponse(minCheckIn), "Negative min fee should throw error", { _ in })

    // Test excessive values for all fees, first one also checks error values

    let excessiveMaxCheckIn = checkIn(withFees: generateFeesResponse(max: excessiveFee), sample: sample)
    XCTAssertThrowsError(try CheckInResponse.validateResponse(excessiveMaxCheckIn),
                         "Excessive max fee should throw error", { error in
                          if let networkError = error as? CKNetworkError,
                            case let .invalidValue(keyPath, value, _) = networkError {
                            XCTAssertEqual(keyPath, FeesResponseKey.max.path, "Incorrect key description")
                            XCTAssertEqual(value, "10000001.0", "Incorrect value description")
                          } else {
                            XCTFail("Excessive fee threw incorrect error type")
                          }
    })

    let excessiveAvgCheckIn = checkIn(withFees: generateFeesResponse(avg: excessiveFee), sample: sample)
    XCTAssertThrowsError(try CheckInResponse.validateResponse(excessiveAvgCheckIn), "Excessive avg fee should throw error", { _ in })

    let excessiveMinCheckIn = checkIn(withFees: generateFeesResponse(min: excessiveFee), sample: sample)
    XCTAssertThrowsError(try CheckInResponse.validateResponse(excessiveMinCheckIn), "Excessive min fee should throw error", { _ in })
  }

  func testValidFeesDoNotThrowError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    let floor: Double = 0
    let ceiling: Double = 10_000_000

    // Floor
    let maxFloorCheckIn = checkIn(withFees: generateFeesResponse(max: floor), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(maxFloorCheckIn), "Floor as max fee should not throw error")
    let avgFloorCheckIn = checkIn(withFees: generateFeesResponse(avg: floor), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(avgFloorCheckIn), "Floor as avg fee should not throw error")
    let minFloorCheckIn = checkIn(withFees: generateFeesResponse(min: floor), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(minFloorCheckIn), "Floor as min fee should not throw error")

    // Ceiling
    let maxCeilingCheckIn = checkIn(withFees: generateFeesResponse(max: ceiling), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(maxCeilingCheckIn), "Ceiling as max fee should not throw error")
    let avgCeilingCheckIn = checkIn(withFees: generateFeesResponse(avg: ceiling), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(avgCeilingCheckIn), "Ceiling as avg fee should not throw error")
    let minCeilingCheckIn = checkIn(withFees: generateFeesResponse(min: ceiling), sample: sample)
    XCTAssertNoThrow(try CheckInResponse.validateResponse(minCeilingCheckIn), "Ceiling as min fee should not throw error")
  }

  private func generateFeesResponse(max: Double = 10,
                                    avg: Double = 10,
                                    min: Double = 10) -> FeesResponse {
    return FeesResponse(max: max, avg: avg, min: min)
  }

  private func checkIn(withPricing pricing: PriceResponse, sample: CheckInResponse) -> CheckInResponse {
    return CheckInResponse(blockheight: sample.blockheight, fees: sample.fees, pricing: pricing)
  }

  private func checkIn(withFees fees: FeesResponse, sample: CheckInResponse) -> CheckInResponse {
    return CheckInResponse(blockheight: sample.blockheight, fees: fees, pricing: sample.pricing)
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

extension CheckInResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> CheckInResponse {
    return CheckInResponse(blockheight: self.blockheight,
                           fees: self.fees.copyWithEmptyRequiredStrings(),
                           pricing: self.pricing.copyWithEmptyRequiredStrings())
  }
}

extension FeesResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> FeesResponse {
    return FeesResponse(max: self.max, avg: self.avg, min: self.min)
  }
}

extension PriceResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> PriceResponse {
    return PriceResponse(last: self.last)
  }
}
