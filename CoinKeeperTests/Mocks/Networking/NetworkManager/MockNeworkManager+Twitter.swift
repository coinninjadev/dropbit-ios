//
//  MockNeworkManager+Twitter.swift
//  DropBit
//
//  Created by BJ Miller on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit
import CoreData
import OAuthSwift

extension MockNetworkManager: TwitterRequestable {
  func authorizeTwitterUser() -> Promise<TwitterOAuthStorage> {
    return Promise { _ in }
  }

  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]> {
    return Promise { _ in }
  }

  func defaultFollowingList() -> Promise<[TwitterUser]> {
    return Promise { _ in }
  }

  func retrieveCurrentUser(with userId: String) -> Promise<TwitterUser> {
    return Promise { _ in }
  }

  var twitterOAuthManager: OAuth1Swift {
    return OAuth1Swift(consumerKey: "", consumerSecret: "")
  }
}
