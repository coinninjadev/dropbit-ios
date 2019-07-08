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
    return "items"
  }
  
  var subPath: String? {
    return nil
  }
  
  public var method: Method {
    return .get
  }
  
  public var task: Task {
    switch self {
    case .news(let count):
      return .requestParameters(parameters: ["count" : count], encoding: URLEncoding.default)
    default:  return .requestPlain
    }
  }
    
  public var headers: [String: String]? {
    switch self {
    default: return nil
    }
  }
    
}
