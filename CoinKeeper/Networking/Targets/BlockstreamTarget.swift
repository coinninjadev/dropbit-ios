//
//  BlockstreamTarget.swift
//  DropBit
//
//  Created by BJ Miller on 4/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Foundation

public enum BlockstreamTarget {
  case sendRawTransaction(String)
}

extension BlockstreamTarget: TargetType {
  public var baseURL: URL {
    return URL(string: "https://blockstream.info/api")!
  }

  public var path: String {
    return "tx"
  }

  public var method: Moya.Method {
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
