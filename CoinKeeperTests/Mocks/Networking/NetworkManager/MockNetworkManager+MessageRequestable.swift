//
//  MockNetworkManager+MessageRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: MessageRequestable {

  func queryForMessages() -> Promise<[MessageResponse]> {
    return Promise { _ in }
  }

}
