//
//  NetworkManager+DropBitMeRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 4/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

protocol UserPublicURLRequestable: AnyObject {

  func getUserPublicURL() -> Promise<UserPublicURLResponse>
  func updateUserPublicURL(enabled: Bool) -> Promise<UserPublicURLResponse>

}

extension NetworkManager: UserPublicURLRequestable {

  func getUserPublicURL() -> Promise<UserPublicURLResponse> {
    return cnProvider.request(UserPublicURLTarget.get)
  }

  func updateUserPublicURL(enabled: Bool) -> Promise<UserPublicURLResponse> {
    let body = UserPublicURLBody(enabled: enabled)
    return cnProvider.request(UserPublicURLTarget.update(body))
  }

}
