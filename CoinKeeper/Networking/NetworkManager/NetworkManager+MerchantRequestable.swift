//
//  NetworkManager+MerchantRequestable.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol MerchantRequestable: AnyObject {
  func fetchMerchants() -> Promise<MerchantConfigurationResponse>
}

extension NetworkManager: MerchantRequestable {

  func fetchMerchants() -> Promise<MerchantConfigurationResponse> {
    return cnProvider.request(MerchantTarget.fetch)
  }

}
