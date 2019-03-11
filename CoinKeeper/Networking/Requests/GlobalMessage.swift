//
//  GlobalMessage.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class GlobalMessage {
  enum Level: String, Codable {
    case fatal
    case error
    case warn
    case success
    case info
    case debug
    case trace

    var displayPriority: Int {
      switch self {
      case .error:
        return 7
      case .warn:
        return 6
      case .success:
        return 5
      case .info, .debug, .trace, .fatal:
        return 0
      }
    }
  }

  enum Platform: String, Codable {
    case ios
    case android
    case all
    case web
  }
}
