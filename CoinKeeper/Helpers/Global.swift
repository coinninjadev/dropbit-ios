//
//  Global.swift
//  DropBit
//
//  Created by Mitch on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum Global {
  enum Key: String {
    case bundle = "CFBundleVersion"
    case version = "CFBundleShortVersionString"
  }

  case build
  case version

  var value: String {
    switch self {
    case .build:
      return Bundle.main.infoDictionary?[Key.bundle.rawValue] as? String ?? ""
    case .version:
      return Bundle.main.infoDictionary?[Key.version.rawValue] as? String ?? ""
    }
  }
}
