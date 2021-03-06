//
//  PriceSummaryResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct PriceSummaryResponse: ResponseDecodable {
  var average: Double
  var time: String
}

extension PriceSummaryResponse {

  static var sampleJSON: String {
    return """
    {
    "average": 178231.123,
    "time": "2019-06-30 00:00:00"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<PriceSummaryResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<PriceSummaryResponse, String?>] { return [] }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(CKDateFormatter.rfc3339Decoding)
    return decoder
  }
}
