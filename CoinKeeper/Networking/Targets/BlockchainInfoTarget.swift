//
//  BlockchainInfoTarget.swift
//  DropBit
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum BlockchainInfoTarget {
  case transaction(String)
}

extension BlockchainInfoTarget: TargetType {

  public var baseURL: URL {
    return URL(string: "https://blockchain.info")!
  }

  public var path: String {
    switch self {
    case .transaction(let txid):  return  "rawtx/\(txid)"
    }
  }

  public var method: Method {
    switch self {
    case .transaction:        return .get
    }
  }

  public var sampleData: Data {
    return ("paste actual sample data here").data(using: .utf8)!
  }

  public var task: Task {
    switch self {
    case .transaction:  return .requestPlain
    }
  }

  public var headers: [String: String]? {
    switch self {
    case .transaction:        return nil
    }
  }

}
