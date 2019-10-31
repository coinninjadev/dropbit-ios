//
//  TwitterOAuthError.swift
//  DropBit
//
//  Created by BJ Miller on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TwitterOAuthError: Error {
  case noUserFound
}

enum TwitterAPIError: Error {
  case rateLimitExceeded(Date)

  var displayMessage: String {
    switch self {
    case .rateLimitExceeded(let retryDate):
      let dateDescription = CKDateFormatter.displayConcise.string(from: retryDate)
      return """
      Twitter has rate limited your account due to too many requests. Please try again after \(dateDescription).
      """
    }
  }
}
