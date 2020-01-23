//
//  CoinNinjaBroadcastTarget.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Foundation

public enum CoinNinjaBroadcastTarget {
  case broadcast(String)
}

extension CoinNinjaBroadcastTarget: TargetType {

  public var baseURL: URL {
    return URL(string: "https://api.coinninja.com/api/v1")!
  }

  public var path: String {
    return "broadcast"
  }

  public var method: Moya.Method {
    return .post
  }

  public var sampleData: Data {
    return ("paste actual sample data here").data(using: .utf8)!
  }

  public var headers: [String: String]? {
    return nil
  }

  public var task: Task {
    switch self {
    case .broadcast(let tx):
      let data = queryBody(encodedTx: tx) ?? Data()
      return .requestCompositeData(bodyData: data, urlParameters: [:])
    }
  }

  private func queryBody(encodedTx: String) -> Data? {
    return encodedTx.data(using: .utf8) ?? Data()
  }

}
