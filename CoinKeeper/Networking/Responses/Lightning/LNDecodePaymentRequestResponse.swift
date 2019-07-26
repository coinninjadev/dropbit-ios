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
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNDecodePaymentRequestResponse, String>] {
    return [\.destination, \.paymentHash]
  }

  static var optionalStringKeys: [WritableKeyPath<LNDecodePaymentRequestResponse, String?>] {
    return [\.description, \.descriptionHash, \.fallbackAddr]
  }

}
