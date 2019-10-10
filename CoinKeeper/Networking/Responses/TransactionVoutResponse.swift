//
//  TransactionVoutResponse.swift
//  DropBit
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TransactionVoutResponseKey: String, KeyPathDescribable {
  typealias ObjectType = TransactionVoutResponse
  case txid, n, value, addresses
}

struct TransactionVoutResponse: ResponseDecodable {
  /// Not part of decoded response, txid of transaction in which this object is a vout
  var txid: String?

  /// index of this vout in the transaction
  let n: Int

  /// amount of this vout from this transaction
  let value: Int

  /// array of addresses as destinations for this vout
  let addresses: [String]

  enum CodingKeys: String, CodingKey {
    case n
    case value
    case scriptPubKey
  }

  enum ScriptPubKeyCodingKeys: String, CodingKey {
    case addresses
  }

  /// Useful for testing
  init(txid: String?, n: Int, value: Int, addresses: [String]) {
    self.txid = txid
    self.n = n
    self.value = value
    self.addresses = addresses
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let scriptPubKeyContainer = try container.nestedContainer(keyedBy: ScriptPubKeyCodingKeys.self, forKey: .scriptPubKey)
    self.addresses = try scriptPubKeyContainer.decode([String].self, forKey: .addresses)
    self.n = try container.decode(Int.self, forKey: .n)
    self.value = try container.decode(Int.self, forKey: .value)
  }

  static func validateResponse(_ response: TransactionVoutResponse) throws -> TransactionVoutResponse {
    guard response.value >= 0 else {
      let path = TransactionVoutResponseKey.value.path
      throw CKNetworkError.invalidValue(keyPath: path, value: String(response.value), response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

  static var sampleJSON: String {
    return """
    {
      "value":100000000,
      "n":0,
      "scriptPubKey":{
        "asm":"OP_DUP OP_HASH160 54aac92eb2398146daa547d921ed29a63891a769 OP_EQUALVERIFY OP_CHECKSIG",
        "hex":"76a91454aac92eb2398146daa547d921ed29a63891a76988ac",
        "reqsigs":1,
        "type":"pubkeyhash",
        "addresses":[
          "18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"
        ]
      }
    }
    """
  }

  static var extraSampleJSON: String {
    return """
    {
      "value":899764244,
      "n":1,
      "scriptPubKey":{
        "asm":"OP_HASH160 cbb86d23f9555a9a2dd084a8feb928b85b927128 OP_EQUAL",
        "hex":"a914cbb86d23f9555a9a2dd084a8feb928b85b92712887",
        "reqsigs":1,
        "type":"scripthash",
        "addresses":[
          "3LGC2ejYwgnV5SKz6vX7TjdCkPVifDTSX8"
        ]
      }
    }
    """
  }

}

extension TransactionVoutResponse {

  static var requiredStringKeys: [KeyPath<TransactionVoutResponse, String>] { return [] }

  //txid is not part of response
  static var optionalStringKeys: [WritableKeyPath<TransactionVoutResponse, String?>] { return [] }

  static var requiredStringArrayKeys: [KeyPath<TransactionVoutResponse, [String]>] {
    return [\.addresses]
  }

}
