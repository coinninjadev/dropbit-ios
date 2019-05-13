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

extension MockNetworkManager: TwitterRequestable {
  func getCurrentTwitterUser() -> Promise<TwitterUser> {
    return Promise { _ in }
  }

  func authorizedTwitterCredentials() -> Promise<TwitterOAuthStorage> {
    return Promise { _ in }
  }
}
