//
//  RegTestBroadcastTarget.swift
//  DropBit
//
//  Created by Ben Winters on 7/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum RegTestBroadcastTarget {
  case sendRawTransaction(String)
}

extension RegTestBroadcastTarget: TargetType {
  public var baseURL: URL {
    return URL(string: "https://api.dev.coinninja.net/api/v1/")!
  }

  public var path: String {
    return "broadcast"
  }

  public var method: Method {
    return .post
  }

  public var sampleData: Data {
    return ("paste actual sample data here").data(using: .utf8)!
  }

  public var task: Task {
    switch self {
    case .sendRawTransaction(let encodedTx):
      let body = encodedTx.data(using: .utf8) ?? Data()
      return .requestData(body)
    }
  }

  public var headers: [String: String]? {
    return nil
  }

  public var validationType: ValidationType {
    return .successCodes
  }
}
