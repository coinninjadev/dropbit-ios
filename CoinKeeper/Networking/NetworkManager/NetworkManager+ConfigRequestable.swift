//
//  NetworkManager+ConfigRequestable.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol ConfigRequestable: AnyObject {
  func fetchConfig() -> Promise<ConfigResponse>
}

extension NetworkManager: ConfigRequestable {

  func fetchConfig() -> Promise<ConfigResponse> {
    return cnProvider.request(ConfigTarget.fetch)
  }

}
