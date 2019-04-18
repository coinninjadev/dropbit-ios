//
//  BlockchainInfoTarget.swift
//  CoinKeeper
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum BlockchainInfoTarget {
  case transaction(String)
  case sendRawTransaction(String)
}

extension BlockchainInfoTarget: TargetType {

  public var baseURL: URL {
    return URL(string: "https://blockchain.info")!
  }

  public var path: String {
    switch self {
    case .transaction(let txid):  return  "rawtx/\(txid)"
    case .sendRawTransaction:     return "pushtx"
    }
  }

  public var method: Method {
    switch self {
    case .transaction:        return .get
    case .sendRawTransaction: return .post
    }
  }

  public var sampleData: Data {
    return ("paste actual sample data here").data(using: .utf8)!
  }

  public var task: Task {
    switch self {
    case .transaction:  return .requestPlain
    case .sendRawTransaction(let encodedTx):
      let body = "tx=\(encodedTx)".data(using: .utf8)!
      return .requestData(body)
    }
  }

  public var headers: [String: String]? {
    switch self {
    case .transaction:        return nil
    case .sendRawTransaction: return nil
    }
  }

}
