//
//  NetworkManager+DropBitMeRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 4/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol DropBitMeRequestable: AnyObject {

  func getDropBitMe() -> Promise<DropBitMeResponse>
  func updateDropBitMe(enabled: Bool) -> Promise<DropBitMeResponse>

}

extension NetworkManager: DropBitMeRequestable {

  func getDropBitMe() -> Promise<DropBitMeResponse> {
    return cnProvider.request(DropBitMeTarget.get)
  }

  func updateDropBitMe(enabled: Bool) -> Promise<DropBitMeResponse> {
    let body = DropBitMeBody(enabled: enabled)
    return cnProvider.request(DropBitMeTarget.update(body))
  }

}
