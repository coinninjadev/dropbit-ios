//
//  AddressTransactionSummaryResponse.swift
//  DropBit
//
//  Created by BJ Miller on 6/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum AddressTransactionSummaryResponseKey: String, KeyPathDescribable {
  typealias ObjectType = AddressTransactionSummaryResponse
  case address, txid, vin, vout, derivativePathResponse
}

struct AddressTransactionSummaryResponse: ResponseDecodable {
  let address: String
  let txid: String
  let vin: Int
  let vout: Int

  let derivativePathResponse: DerivativePathResponse?

  init(
    addressTransactionSummaryResponse atsResponse: AddressTransactionSummaryResponse,
    derivativePathResponse dpResponse: DerivativePathResponse?
    ) {

    self.address = atsResponse.address
    self.txid = atsResponse.txid
    self.vin = atsResponse.vin
    self.vout = atsResponse.vout
    self.derivativePathResponse = dpResponse
  }
}

extension AddressTransactionSummaryResponse {

  static var requiredStringKeys: [KeyPath<AddressTransactionSummaryResponse, String>] {
    return [\.address, \.txid]
  }

  static var optionalStringKeys: [WritableKeyPath<AddressTransactionSummaryResponse, String?>] { return [] }

  static var sampleJSON: String {
    return """
    {
    "address": "1Gy2Ast7uT13wQByPKs9Vi9Qj1BVcARgVQ",
    "blockhash": "0000000000000000001354f6f773c6e452420c7d75b6a45f1ae8e904e8353550",
    "txid": "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83",
    "time": 1520972149,
    "vin": 2058617,
    "vout": 0
    }
    """
  }

  init(txid: String, address: String, vin: Int, vout: Int) {
    self.txid = txid
    self.address = address
    self.vin = vin
    self.vout = vout
    self.derivativePathResponse = nil
  }

  static func validateResponse(_ response: AddressTransactionSummaryResponse) throws -> AddressTransactionSummaryResponse {
    guard response.vin >= 0 else {
      let path = AddressTransactionSummaryResponseKey.vin.path
      throw DBTError.Network.invalidValue(keyPath: path, value: String(response.vin), response: response)
    }

    guard response.vout >= 0 else {
      let path = AddressTransactionSummaryResponseKey.vout.path
      throw DBTError.Network.invalidValue(keyPath: path, value: String(response.vout), response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()

    return stringValidatedResponse
  }

}

extension AddressTransactionSummaryResponse: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(txid)
    hasher.combine(address)
  }

  static func == (lhs: AddressTransactionSummaryResponse, rhs: AddressTransactionSummaryResponse) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
