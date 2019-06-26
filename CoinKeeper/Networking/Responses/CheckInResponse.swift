//
//  CheckInResponse.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Main object managing response json from check-in api.
struct CheckInResponse: ResponseCodable {
  let blockheight: Int
  let fees: FeesResponse
  let pricing: PriceResponse

  init(blockheight: Int, fees: FeesResponse, pricing: PriceResponse) {
    self.blockheight = blockheight
    self.fees = fees
    self.pricing = pricing
  }

}

enum FeesResponseKey: String, KeyPathDescribable {
  typealias ObjectType = FeesResponse
  case max, avg, min
}

/// Response object for fees structure inside check-in api response
struct FeesResponse: ResponseCodable {
  let max: Double
  let avg: Double
  let min: Double

  var good: Double {
    return min
  }

  var better: Double {
    return avg
  }

  var best: Double {
    return max
  }

  /// Fees must be greater than or equal to this number
  static let validFeeFloor: Double = 0

  /// Fees must be less than or equal to this number
  static let validFeeCeiling: Double = 10_000_000

  static func validateResponse(_ response: FeesResponse) throws -> FeesResponse {
    let maxFee = response.max
    let avgFee = response.avg
    let minFee = response.min

    let maxError = CKNetworkError.invalidValue(keyPath: FeesResponseKey.max.path, value: String(maxFee), response: response)
    let avgError = CKNetworkError.invalidValue(keyPath: FeesResponseKey.avg.path, value: String(avgFee), response: response)
    let minError = CKNetworkError.invalidValue(keyPath: FeesResponseKey.min.path, value: String(minFee), response: response)

    guard validFeeFloor <= maxFee && maxFee <= validFeeCeiling else { throw maxError }
    guard validFeeFloor <= avgFee && avgFee <= validFeeCeiling else { throw avgError }
    guard validFeeFloor <= minFee && minFee <= validFeeCeiling else { throw minError }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

  static var sampleJSON: String {
    return """
    {
    "max": 347.222,
    "avg": 12.425,
    "min": 0.98785
    }
    """
  }

  static var requiredStringKeys: [KeyPath<FeesResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<FeesResponse, String?>] { return [] }

}

enum PriceResponseKey: String, KeyPathDescribable {
  typealias ObjectType = PriceResponse
  case last
}

/// Response object for price structure inside check-in api response
struct PriceResponse: ResponseCodable {

  let last: Double

  static func validateResponse(_ response: PriceResponse) throws -> PriceResponse {
    guard response.last > 0 else {
      throw CKNetworkError.invalidValue(keyPath: PriceResponseKey.last.path, value: String(response.last), response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

  static var sampleJSON: String {
    return """
    {
      "last": 6496.79,
      "timestamp": 1458754392
    }
    """
  }

  static var requiredStringKeys: [KeyPath<PriceResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<PriceResponse, String?>] { return [] }

}

extension CheckInResponse {

  static var sampleJSON: String {
    return """
    {
    "blockheight": 518631,
    "fees": \(FeesResponse.sampleJSON),
    "pricing": \(PriceResponse.sampleJSON)
    }
    """
  }

  static func validateResponse(_ response: CheckInResponse) throws -> CheckInResponse {
    let stringValidatedFeesResponse = try FeesResponse.validateResponse(response.fees)
    let stringValidatedPriceResponse = try PriceResponse.validateResponse(response.pricing)

    // Create new CheckInResponse with FeesResponse and PriceResponse in case they had an empty string that was changed to nil during validation.
    let candidateCheckInResponse = CheckInResponse(blockheight: response.blockheight,
                                                   fees: stringValidatedFeesResponse,
                                                   pricing: stringValidatedPriceResponse)

    let stringValidatedCheckInResponse = try candidateCheckInResponse.validateStringValues()
    return stringValidatedCheckInResponse
  }

  static var requiredStringKeys: [KeyPath<CheckInResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<CheckInResponse, String?>] { return [] }

}
