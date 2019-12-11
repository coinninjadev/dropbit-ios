//
//  MockNetworkManager+ConfigRequestable.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit

extension MockNetworkManager: ConfigRequestable {

  func fetchConfig() -> Promise<ConfigResponse> {
    let mockResponse = ConfigResponse(updatedAt: nil, config: ConfigResponseItems(buy: [], referral: nil))
    return Promise.value(mockResponse)
  }

}
