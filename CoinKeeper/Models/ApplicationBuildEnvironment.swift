//
//  ApplicationBuildEnvironment.swift
//  DropBit
//
//  Created by BJ Miller on 10/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum ApplicationBuildEnvironment: String {
  case prod
  case debug

  static func current() -> ApplicationBuildEnvironment {
    #if DEBUG
    return .debug
    #else
    return .prod
    #endif
  }
}
