//
//  TwitterEndpoints.swift
//  DropBit
//
//  Created by BJ Miller on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TwitterEndpoints {
  case getUser
  case search
  case friends

  var urlString: String {
    switch self {
    case .getUser: return "https://api.twitter.com/1.1/users/show.json"
    case .search: return "https://api.twitter.com/1.1/users/search.json"
    case .friends: return "https://api.twitter.com/1.1/friends/list.json"
    }
  }
}
