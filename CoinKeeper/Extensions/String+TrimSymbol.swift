//
//  String+TrimSymbol.swift
//  DropBit
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension String {

  func removing(groupingSeparator: String, currencySymbol: String) -> String {
    return removing(groupingSeparator: groupingSeparator, currencySymbols: [currencySymbol])
  }

  func removing(groupingSeparator: String, currencySymbols: [String]) -> String {
    let withoutSeparator = self.components(separatedBy: groupingSeparator).joined(separator: "")
    var withoutSymbol = withoutSeparator
    for symbol in currencySymbols {
     withoutSymbol = withoutSymbol.replacingOccurrences(of: symbol, with: "")
    }

    return withoutSymbol
  }

  /// Replaces any random whitespace with a single space
  func stringByStandardizingWhitespaces() -> String {
    let components = self.components(separatedBy: .whitespacesAndNewlines)
    return components.filter { $0.isNotEmpty }.joined(separator: " ")
  }

  func removingNonDecimalCharacters(keepingCharactersIn customString: String = "") -> String {
    let customSet = CharacterSet(charactersIn: customString)
    let charactersToKeep = CharacterSet.decimalDigits.union(customSet)
    let charactersToRemove = charactersToKeep.inverted
    return self.components(separatedBy: charactersToRemove).joined()
  }

  func asNilIfEmpty() -> String? {
    return self.isEmpty ? nil : self
  }

  /// Drops first character from string if it matches the parameter
  func dropFirstCharacter(ifEquals char: Character) -> String {
    if self.first == char {
      return String(self.dropFirst())
    } else {
      return self
    }
  }

  func replacingOccurrences(of substrings: [String], with replacement: String) -> String {
    if let firstSubstring = substrings.first {
      let partiallyReplaced = self.replacingOccurrences(of: firstSubstring, with: replacement)
      let remainingSubstrings = substrings.dropFirst()
      return partiallyReplaced.replacingOccurrences(of: Array(remainingSubstrings), with: replacement)
    } else {
      return self
    }
  }

}
