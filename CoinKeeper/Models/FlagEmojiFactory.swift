//
//  FlagEmojiFactory.swift
//  DropBit
//
//  Created by Ben Winters on 2/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct FlagEmojiFactory {

  func emojiFlag(for regionCode: String) -> String? {
    let lowercasedCode = regionCode.lowercased()
    guard lowercasedCode.count == 2 else { return nil }
    let cumulativeResult = lowercasedCode.unicodeScalars.reduce(true, { accum, scalar in
      return accum && isLowercaseASCIIScalar(scalar) }
    )
    guard cumulativeResult == true else { return nil }

    let indicatorSymbols = lowercasedCode.unicodeScalars.compactMap { regionalIndicatorSymbol(for: $0) }
    return String(indicatorSymbols.map({ Character($0) }))
  }

  private func isLowercaseASCIIScalar(_ scalar: Unicode.Scalar) -> Bool {
    return scalar.value >= 0x61 && scalar.value <= 0x7A
  }

  private func regionalIndicatorSymbol(for scalar: Unicode.Scalar) -> Unicode.Scalar? {
    precondition(isLowercaseASCIIScalar(scalar))

    // 0x1F1E6 marks the start of the Regional Indicator Symbol range and corresponds to 'A'
    // 0x61 marks the start of the lowercase ASCII alphabet: 'a'
    return Unicode.Scalar(scalar.value + (0x1F1E6 - 0x61))
  }

}
