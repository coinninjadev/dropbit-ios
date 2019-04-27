//
//  String+Substrings.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension String {

  /// This method makes it easier extract a substring by character index where a character is viewed as a human-readable character (grapheme cluster).
  internal func substring(start: Int, offsetBy: Int) -> String? {
    guard let substringStartIndex = self.index(startIndex, offsetBy: start, limitedBy: endIndex) else {
      return nil
    }

    guard let substringEndIndex = self.index(startIndex, offsetBy: start + offsetBy, limitedBy: endIndex) else {
      return nil
    }

    return String(self[substringStartIndex ..< substringEndIndex])
  }

  internal func containsAny(_ substrings: [String]) -> Bool {
    for substring in substrings where self.contains(substring) {
      return true
    }

    return false
  }

  internal func containsNone(_ substrings: [String]) -> Bool {
    return !containsAny(substrings)
  }

  func lowercasingFirstLetter() -> String {
    return prefix(1).lowercased() + self.dropFirst()
  }

}
