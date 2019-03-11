//
//  TransactionResponse.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TransactionResponseKey: String, KeyPathDescribable {
  typealias ObjectType = TransactionResponse
  case txid, blockHash, date, sortDate, blockheight, receivedTime, voutResponses, vinResponses
}

extension TransactionResponse {
  static var requiredStringKeys: [KeyPath<TransactionResponse, String>] {
    return [\.txid]
  }

  static var optionalStringKeys: [WritableKeyPath<TransactionResponse, String?>] {
    return [\.blockHash]
  }

}

struct TransactionResponse: ResponseDecodable {
  /// id of this transaction
  let txid: String

  /// block hash in which this transaction belongs. nil if not mined yet.
  var blockHash: String?

  /// time. nil if not mined yet.
  let date: Date?

  /// computed during decoding. if 0 < receivedTime < time, use receivedTime. else use time.
  let sortDate: Date?

  /// blockheight of transaction. nil if not mined yet.
  let blockheight: Int?

  /// time received into Coin Ninja's nodes' mempool. nil if not received, 0 TimeInterval, or dropped from mempool.
  let receivedTime: Date?

  /// Not decoded from response, is calculated before saving to CKMTransaction object
  var isSentToSelf = false

  let voutResponses: [TransactionVoutResponse]
  let vinResponses: [TransactionVinResponse]

  enum CodingKeys: String, CodingKey {
    case txid
    case blockHash = "blockhash"
    case date = "time"
    case blockheight
    case receivedTime = "received_time"
    case vout
    case vin
  }

  enum VoutCodingKeys: String, CodingKey {
    case vout
  }

  enum VinCodingKeys: String, CodingKey {
    case vin
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.txid = try container.decode(String.self, forKey: .txid)
    self.blockHash = try container.decodeIfPresent(String.self, forKey: .blockHash)
    let blockheightValue = try container.decodeIfPresent(Int.self, forKey: .blockheight)
    self.blockheight = (blockheightValue == 0) ? nil : blockheightValue

    let timeInterval = try container.decode(TimeInterval.self, forKey: .date)
    self.date = timeInterval == 0 ? nil : Date(timeIntervalSince1970: timeInterval)

    let receivedTimeInterval = try container.decode(TimeInterval.self, forKey: .receivedTime)
    self.receivedTime = receivedTimeInterval == 0 ? nil : Date(timeIntervalSince1970: receivedTimeInterval)
    if receivedTimeInterval > 0 && receivedTimeInterval < timeInterval {
      self.sortDate = Date(timeIntervalSince1970: receivedTimeInterval)
    } else {
      self.sortDate = Date(timeIntervalSince1970: timeInterval)
    }

    var voutContainer = try container.nestedUnkeyedContainer(forKey: .vout)
    var maybeVoutResponses: [TransactionVoutResponse] = []
    while !voutContainer.isAtEnd {
      var maybeVoutResponse = try voutContainer.decode(TransactionVoutResponse.self)
      maybeVoutResponse.txid = self.txid
      maybeVoutResponses.append(maybeVoutResponse)
    }
    self.voutResponses = maybeVoutResponses

    var vinContainer = try container.nestedUnkeyedContainer(forKey: .vin)
    var maybeVinResponses: [TransactionVinResponse] = []
    while !vinContainer.isAtEnd {
      var maybeVinResponse = try vinContainer.decode(TransactionVinResponse.self)
      maybeVinResponse.currentTxid = self.txid
      maybeVinResponses.append(maybeVinResponse)
    }
    self.vinResponses = maybeVinResponses
  }
}

extension TransactionResponse {

  init(txid: String,
       blockHash: String?,
       date: Date?,
       sortDate: Date?,
       blockheight: Int?,
       receivedTime: Date?,
       isSentToSelf: Bool,
       vinResponses: [TransactionVinResponse],
       voutResponses: [TransactionVoutResponse]) {
    self.txid = txid
    self.blockHash = blockHash
    self.date = date
    self.sortDate = sortDate
    self.blockheight = blockheight
    self.receivedTime = receivedTime
    self.isSentToSelf = isSentToSelf
    self.vinResponses = vinResponses
    self.voutResponses = voutResponses
  }

  /// A partial initializer for testing
  init(txid: String, blockheight: Int? = nil, vinResponses: [TransactionVinResponse] = [], voutResponses: [TransactionVoutResponse] = []) {
    self.init(txid: txid,
              blockHash: nil,
              date: nil,
              sortDate: Date(),
              blockheight: blockheight,
              receivedTime: nil,
              isSentToSelf: false,
              vinResponses: vinResponses,
              voutResponses: voutResponses)
  }

  static var decoder: JSONDecoder {
    return JSONDecoder()
  }

  static var sampleJSON: String {
    return """
    {
    "txid":"7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
    "hash":"ee90a9ec4bbcf1ab327a6489a74a393b85515bc5bf8d308a3201b19974445276",
    "blockhash":"0000000000000000007aba266efd9aedfc005b69539bf077d1eaffb4a5fb9272",
    "height":21,
    "version":1,
    "size":249,
    "vsize":168,
    "weight":669,
    "time":1514906608,
    "blocktime":1514906608,
    "locktime":0,
    "vin":[
    \(TransactionVinResponse.sampleJSON)
    ],
    "vout":[
    \(TransactionVoutResponse.sampleJSON),
    \(TransactionVoutResponse.extraSampleJSON)
    ],
    "coinbase":false,
    "blockheight":502228,
    "blocks":[
    "0000000000000000007aba266efd9aedfc005b69539bf077d1eaffb4a5fb9272"
    ],
    "received_time": 1514906608
    }
    """
  }

  static func validateResponse(_ response: TransactionResponse) throws -> TransactionResponse {
    if let minedBlockheight = response.blockheight {
      guard minedBlockheight > 0 else {
        let path = TransactionResponseKey.blockheight.path
        throw CKNetworkError.invalidValue(keyPath: path, value: String(minedBlockheight), response: response)
      }
    }

    let stringValidatedVinResponses = try response.vinResponses.map { try TransactionVinResponse.validateResponse($0) }
    let stringValidatedVoutResponses = try response.voutResponses.map { try TransactionVoutResponse.validateResponse($0) }

    // Create new TransactionResponse with vin and vout response in case they had an empty string that was changed to nil during validation.
    let candidateTransactionResponse = response.copy(withVinResponse: stringValidatedVinResponses,
                                                     voutResponses: stringValidatedVoutResponses)

    let stringValidatedResponse = try candidateTransactionResponse.validateStringValues()
    return stringValidatedResponse
  }

  func copy(withVinResponse vinResponses: [TransactionVinResponse],
            voutResponses: [TransactionVoutResponse]) -> TransactionResponse {
    return TransactionResponse(txid: self.txid,
                               blockHash: self.blockHash,
                               date: self.date,
                               sortDate: self.sortDate,
                               blockheight: self.blockheight,
                               receivedTime: self.receivedTime,
                               isSentToSelf: self.isSentToSelf,
                               vinResponses: vinResponses,
                               voutResponses: voutResponses)
  }

}

extension TransactionResponse: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(txid)
  }

  static func == (lhs: TransactionResponse, rhs: TransactionResponse) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
