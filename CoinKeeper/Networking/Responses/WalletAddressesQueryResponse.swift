//
//  WalletAddressesQueryResponse.swift
//  DropBit
//
//  Created by Ben Winters on 1/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct WalletAddressesQueryResponse: ResponseCodable {

  let identityHash: String
  let address: String
  var addressPubkey: String?

  static var sampleJSON: String {
    return """
    {
      "identity_hash": "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49",
      "address": "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw",
      "address_pubkey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8xOUetsCa8EfOlDEBAfREhJqspDoyEh6Szz2in47Tv5n52m9dLYyPCbqZkOB5nTSqtscpkQD/HpykCggvx09iQ=="
    }
    """
  }

  static var requiredStringKeys: [KeyPath<WalletAddressesQueryResponse, String>] {
    return [\.identityHash, \.address]
  }

  static var optionalStringKeys: [WritableKeyPath<WalletAddressesQueryResponse, String?>] {
    return [\.addressPubkey]
  }

}
