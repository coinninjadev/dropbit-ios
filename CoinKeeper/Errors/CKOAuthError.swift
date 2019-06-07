//
//  CKOAuthError.swift
//  DropBit
//
//  Created by BJ Miller on 6/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CKOAuthError: Int, Error {
  case invalidOrExpiredToken = -11

  var errorCode: Int {
    return self.rawValue
  }

  var localizedDescription: String {
    switch self {
    case .invalidOrExpiredToken:
      return "The session token is invalid or has expired. Please close and try again."
    }
  }
}
