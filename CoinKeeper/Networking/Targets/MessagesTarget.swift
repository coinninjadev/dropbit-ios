//
//  MessagesTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum MessagesTarget: CoinNinjaTargetType {
  typealias ResponseType = MessageResponse

  case query(ElasticRequest)

  var basePath: String {
    return "messages"
  }

  var subPath: String? {
    switch self {
    case .query: return "query"
    }
  }

  public var task: Task {
    switch self {
    case .query(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

  public var method: Method {
    switch self {
    case .query: return .post
    }
  }

}
