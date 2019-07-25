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
  let numSatoshis: String
  let timestamp: Date
  let expiry: Date
  let description: String
  let descriptionHash: String
  let fallbackAddr: String
  let cltvExpiry: Date
  let routeHints: [LNRouteHint]

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNDecodePaymentRequestResponse, String>] {
    return [\.destination, \.paymentHash, \.numSatoshis, \.description,
            \.descriptionHash, \.fallbackAddr]
  }

  static var optionalStringKeys: [WritableKeyPath<LNDecodePaymentRequestResponse, String?>] {
    return []
  }

}
