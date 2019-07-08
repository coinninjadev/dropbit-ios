//
//  NewsTarget.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum NewsTarget: CoinNinjaTargetType {
  typealias ResponseType = NewsArticleResponse

  case news(Int)
}

extension NewsTarget {

  var basePath: String {
    switch self {
    case .news(let count):
    return "news/feed/items?count=\(count)"
    }
  }

  var subPath: String? {
    return nil
  }

  public var method: Method {
    return .get
  }

  public var task: Task {
    return .requestPlain
  }

  public var headers: [String: String]? {
    switch self {
    default: return nil
    }
  }

}
