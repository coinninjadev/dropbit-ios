//
//  CoinNinjaBroadcastResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct CoinNinjaBroadcastResponse {
  var success: String
}

extension CoinNinjaBroadcastResponse: ResponseDecodable {

  static var sampleJSON: String {
    return """
      Success
    """
  }

  static var requiredStringKeys: [KeyPath<CoinNinjaBroadcastResponse, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<CoinNinjaBroadcastResponse, String?>] { return [] }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(CKDateFormatter.rfc3339Decoding)
    return decoder
  }
}
