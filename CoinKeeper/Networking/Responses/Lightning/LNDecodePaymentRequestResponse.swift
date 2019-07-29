//
//  LNDecodePaymentRequestResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

struct LNRouteHint: Decodable {
  let hopHints: [LNHopHint]
}

struct LNHopHint: Decodable {
  let nodeId: String
  let chanId: String
  let feeBaseMsat: Int
  let feeProportionalMillionths: Int
  let cltvExpiryDelta: Int
}

struct LNDecodePaymentRequestResponse: LNResponseDecodable {

  let destination: String
  let paymentHash: String
  let numSatoshis: Int
  let timestamp: Date
  let expiry: Int
  var description: String?
  var descriptionHash: String?
  var fallbackAddr: String?
  let cltvExpiry: Int
  let routeHints: [LNRouteHint]

  enum CodingKeys: String, CodingKey {
    case destination, paymentHash, numSatoshis, timestamp, expiry,
    description, descriptionHash, fallbackAddr, cltvExpiry, routeHints
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = "LNDecodePaymentRequestResponse"

    destination = try container.decode(String.self, forKey: .destination)
    paymentHash = try container.decode(String.self, forKey: .paymentHash)
    numSatoshis = try container.decodeStringAsInt(forKey: .numSatoshis, typeName: typeName)
    let timestampSeconds = try container.decodeStringAsInt(forKey: .timestamp, typeName: typeName)
    self.timestamp = Date(timeIntervalSince1970: Double(timestampSeconds))
    self.expiry = try container.decodeStringAsInt(forKey: .expiry, typeName: typeName)
    self.description = try container.decode(String.self, forKey: .description).asNilIfEmpty()
    self.descriptionHash = try container.decode(String.self, forKey: .descriptionHash).asNilIfEmpty()
    self.fallbackAddr = try container.decode(String.self, forKey: .fallbackAddr).asNilIfEmpty()
    self.cltvExpiry = try container.decodeStringAsInt(forKey: .cltvExpiry, typeName: typeName)
    self.routeHints = try container.decode([LNRouteHint].self, forKey: .routeHints)
  }

  static var sampleJSON: String {
    return """
    {
    "num_satoshis" : "2000",
    "destination" : "0357b3bb3fdedb369d2bdb429b6c397b207169bc8933e6f37e926e18b2f6c560f1",
    "expiry" : "3600",
    "fallback_addr" : "",
    "route_hints" : [

    ],
    "description_hash" : "",
    "cltv_expiry" : "40",
    "description" : "Test request generated at: 2019-07-29 15:03:29 +0000",
    "timestamp" : "1564412609",
    "payment_hash" : "59da58f1b9ab6bb1b89659bfb5bd48a0221c40ddd2b5dcea3b25fb5843b58d9c"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<LNDecodePaymentRequestResponse, String>] {
    return [\.destination, \.paymentHash]
  }

  static var optionalStringKeys: [WritableKeyPath<LNDecodePaymentRequestResponse, String?>] {
    return [\.description, \.descriptionHash, \.fallbackAddr]
  }

}
