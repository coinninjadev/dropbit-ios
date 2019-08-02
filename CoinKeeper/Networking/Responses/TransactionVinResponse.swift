//
//  TransactionVinResponse.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TransactionVinResponseKey: String, KeyPathDescribable {
  typealias ObjectType = TransactionVinResponse
  case currentTxid, txid, vout, value, addresses
}

struct TransactionVinResponse: ResponseDecodable {
  /// Not part of decoded response, txid of transaction in which this object is a vin
  var currentTxid: String?

  /// referenced txid from previous transaction
  let txid: String

  /// index in previous transaction which this vin references
  let vout: Int

  /// amount of this vin into this transaction
  let value: Int

  /// array of addresses providing this vin
  let addresses: [String]

  static var requiredStringKeys: [KeyPath<TransactionVinResponse, String>] {
    return [\.txid]
  }

  // currentTxid is not part of decoded response
  static var optionalStringKeys: [WritableKeyPath<TransactionVinResponse, String?>] { return [] }

  static var requiredStringArrayKeys: [KeyPath<TransactionVinResponse, [String]>] {
    return [\.addresses]
  }

  // do same shenanigans to get nested data
  enum CodingKeys: String, CodingKey {
    case txid
    case vout  // `vout` represents the `n` index of the vout from the previous transaction
    case previousOutput = "previousoutput"
  }

  enum PreviousOutputCodingKeys: String, CodingKey {
    case value
    case scriptPubKey
  }

  enum ScriptPubKeyCodingKeys: String, CodingKey {
    case addresses
  }

  /// Useful for testing
  init(currentTxid: String? = nil,
       txid: String,
       vout: Int,
       value: Int,
       addresses: [String] = []) {
    self.currentTxid = currentTxid
    self.txid = txid
    self.vout = vout
    self.value = value
    self.addresses = addresses
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.txid = try container.decode(String.self, forKey: .txid)
    self.vout = try container.decode(Int.self, forKey: .vout)

    let previousOutputContainer = try container.nestedContainer(keyedBy: PreviousOutputCodingKeys.self, forKey: .previousOutput)
    self.value = try previousOutputContainer.decode(Int.self, forKey: .value)

    let scriptPubKeyContainer = try previousOutputContainer.nestedContainer(keyedBy: ScriptPubKeyCodingKeys.self, forKey: .scriptPubKey)
    self.addresses = try scriptPubKeyContainer.decodeIfPresent([String].self, forKey: .addresses) ?? []
  }

  static func validateResponse(_ response: TransactionVinResponse) throws -> TransactionVinResponse {
    guard response.vout >= 0 else {
      throw CKNetworkError.invalidValue(keyPath: TransactionVinResponseKey.vout.path,
                                        value: String(response.vout),
                                        response: response)
    }

    guard response.value >= 0 else {
      throw CKNetworkError.invalidValue(keyPath: TransactionVinResponseKey.value.path,
                                        value: String(response.value),
                                        response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

  static var sampleJSON: String {
    return """
    {
      "txid":"69151603ebe4192d50c1aaaca4e0ab0ea335184e261376c2eda64c35ce9fd1b5",
      "vout":1,
      "scriptSig":{
        "asm":"00142f0908d7a15b75bfacb22426b5c1d78f545a683f",
        "hex":"1600142f0908d7a15b75bfacb22426b5c1d78f545a683f"
      },
      "txinwitness":[
        "304402204dcaba494328bd472f4bf61761e43c9ca204ea81ce9c5c57d669e4ed4721499f022007a6024b0f5e202a7f38bb90edbecaa788e276239a12aa42d95881",
        "036ebf6ab96773a9fa7997688e1712ddc9722ef9274220ba406cb050ac5f1a1306"
      ],
      "sequence":4294967295,
      "coinbase":"",
      "previousoutput":{
        "value":999934902,
        "n":1,
        "scriptPubKey":{
          "asm":"OP_HASH160 4f7728b2a54dc9a2b44e47341e7e029bb99c7d72 OP_EQUAL",
          "hex":"a9144f7728b2a54dc9a2b44e47341e7e029bb99c7d7287",
          "reqsigs":1,
          "type":"scripthash",
          "addresses":[
            "38wC41V2tNZrr2uiwUthn41b2M8SLGMVRt"
          ]
        }
      }
    }
    """
  }
}
