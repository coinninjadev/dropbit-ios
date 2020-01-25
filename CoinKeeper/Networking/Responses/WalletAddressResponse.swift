//
//  AddWalletAddress.swift
//  DropBit
//
//  Created by Ben Winters on 5/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct AddWalletAddressBody: Encodable {
  let address: String
  let addressPubkey: String
  let addressType: String

  /// Provide this if the addresses are being added in response to a request for addresses
  let walletAddressRequestId: String?

  init(address: String, pubkey: String, type: WalletAddressType, walletAddressRequestId: String?) {
    self.address = address
    self.addressPubkey = pubkey
    self.addressType = type.rawValue
    self.walletAddressRequestId = walletAddressRequestId
  }

}

/// Encodable for logging invalid responses
public struct WalletAddressResponse: ResponseCodable {
  let id: String
  let createdAt: Date
  let updatedAt: Date
  let address: String
  let walletId: String
  var addressPubkey: String? // may not exist for older addresses
  var addressType: String?  // may not exist for older addresses

  var addressTypeCase: WalletAddressType {
    guard let typeString = addressType,
      let typeCase = WalletAddressType(rawValue: typeString) else {
      return .btc
    }
    return typeCase
  }

  /// Useful for testing
  init(id: String = UUID().uuidString,
       createdAt: Date = Date(),
       updatedAt: Date = Date(),
       address: String,
       addressPubkey: String?,
       walletId: String = UUID().uuidString) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.address = address
    self.addressPubkey = addressPubkey
    self.walletId = walletId
  }

  var jsonDescription: String {
    let data = try? JSONEncoder().encode(self)
    return data.flatMap { String(data: $0, encoding: .utf8) } ?? "-"
  }

}

extension WalletAddressResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "6d1d7318-81b9-492c-b3f3-9d1b24f91d14",
    "created_at": 1525882145,
    "updated_at": 1525885745,
    "address": "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw",
    "wallet_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d",
    "address_pubkey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8xOUetsCa8EfOlDEBAfREhJqspDoyEh6Szz2in47Tv5n52m9dLYyPCbqZkOB5nTSqtscpkQD/HpykCggvx09iQ=="
    }
    """
  }

  static var requiredStringKeys: [KeyPath<WalletAddressResponse, String>] {
    return [\.id, \.address, \.walletId]
  }

  static var optionalStringKeys: [WritableKeyPath<WalletAddressResponse, String?>] {
    return [\.addressPubkey, \.addressType]
  }

}
