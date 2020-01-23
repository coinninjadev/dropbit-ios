//
//  LNDecodePaymentRequestResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

struct LNDecodePaymentRequestResponse: LNResponseDecodable {

  let numSatoshis: Int?
  var description: String?
  let isExpired: Bool
  let expiresAt: Date

  static var sampleJSON: String {
    return """
    {
    "num_satoshis" : 2000,
    "destination" : "0357b3bb3fdedb369d2bdb429b6c397b207169bc8933e6f37e926e18b2f6c560f1",
    "expiry" : 3600,
    "fallback_addr" : "",
    "route_hints" : nil,
    "description_hash" : "",
    "cltv_expiry" : 40,
    "description" : "Test request generated at: 2019-07-31 14:17:04 +0000",
    "timestamp" : "2019-07-31T14:17:04.000000Z",
    "payment_hash" : "59da58f1b9ab6bb1b89659bfb5bd48a0221c40ddd2b5dcea3b25fb5843b58d9c"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<LNDecodePaymentRequestResponse, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<LNDecodePaymentRequestResponse, String?>] {
    return [\.description]
  }

}
