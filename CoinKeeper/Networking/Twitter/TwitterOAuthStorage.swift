//
//  TwitterOAuthStorage.swift
//  DropBit
//
//  Created by BJ Miller on 5/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct TwitterOAuthStorage {
  let twitterOAuthToken: String
  let twitterOAuthTokenSecret: String
  let twitterUserId: String
  let twitterScreenName: String
}

extension TwitterOAuthStorage {
  var formattedScreenName: String {
    return "@" + twitterScreenName
  }
}
