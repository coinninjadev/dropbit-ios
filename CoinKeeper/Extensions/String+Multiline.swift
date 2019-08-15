//
//  String+Multiline.swift
//  CoinKeeper
//
//  Created by Ben Winters on 8/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension String {

  /// Use this when using a multiline string literal in code, but want to display it without line breaks.
  /// Be careful not to indent text inside of the multiline string literal because that will result in extra spaces.
  func removingMultilineLineBreaks(replaceBreaksWithSpaces: Bool = true) -> String {
    let replacementString = replaceBreaksWithSpaces ? " " : ""
    return self.replacingOccurrences(of: "\n", with: replacementString)
  }

}
