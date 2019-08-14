//
//  UITestHelpers.swift
//  DropBitUITests
//
//  Created by BJ Miller on 11/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct UITestHelpers {

  /// IMPORTANT: Do not use these words for tests where a transaction could be generated.
  /// The next receive address for these words should always be at index 0.
  static func recoverOnlyWords() -> [String] {
    return GeneratedTestWords.recoverOnlyWords
  }

  static var recoverOnlyWordsFirstAddress: String {
    return GeneratedTestWords.recoverOnlyFirstTestnetAddress
  }

}
