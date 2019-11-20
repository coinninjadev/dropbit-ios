//
//  MockNetworkManager+MerchantRequestable.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 11/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit

extension MockNetworkManager: MerchantRequestable {

  func fetchMerchants() -> Promise<MerchantConfigurationResponse> {
    return Promise { _ in }
  }

}
