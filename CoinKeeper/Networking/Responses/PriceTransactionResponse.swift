//
//  PriceTransactionResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum PriceTransactionResponseKey: String, KeyPathDescribable {
  typealias ObjectType = PriceTransactionResponse
  case average
}

struct PriceTransactionResponse: ResponseCodable {

  //Ignoring this field because date format is incompatible with our decoder date formatters ("2018-06-26 18:00:00")
  //var time: Date?

  let average: Double

}

extension PriceTransactionResponse {

  var averagePrice: NSDecimalNumber {
    return NSDecimalNumber(value: average).rounded(forCurrency: .USD)
  }

  static var sampleJSON: String {
    return """
    {
    "time": "2016-05-17 00:00:00",
    "average": 457.91
    }
    """
  }

  static func validateResponse(_ response: PriceTransactionResponse) throws -> PriceTransactionResponse {
    let path = PriceTransactionResponseKey.average.path
    let avg = response.average

    guard avg > 0 else {
      throw DBTError.Network.invalidValue(keyPath: path, value: String(avg), response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

  static var requiredStringKeys: [KeyPath<PriceTransactionResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<PriceTransactionResponse, String?>] { return [] }

}
