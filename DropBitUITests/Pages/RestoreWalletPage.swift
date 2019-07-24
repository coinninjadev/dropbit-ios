//
//  RestoreWalletPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class RestoreWalletPage: UITestPage {

  init() {
    super.init(page: .restoreWallet(.page))
  }

  @discardableResult
  func enterWords(_ words: [String]) -> Self {
    let textField = app.textFields(.restoreWallet(.wordTextField))

    for (index, word) in words.enumerated() {
      let wordNumber = index + 1
      let wordProgressText = wordEntryProgressLabel(number: wordNumber)
      let wordProgressLabel = app.staticTexts[wordProgressText]
      wordProgressLabel.assertExistence(afterWait: .none, elementDesc: wordProgressText)

      textField.typeText(word)
      let resultButton = app.buttons[word.lowercased()]
      resultButton.assertExistence(afterWait: .none, elementDesc: "resultButton for \(word), number: \(wordNumber)")
      resultButton.tap()
    }

    return self
  }

  private func wordEntryProgressLabel(number: Int) -> String {
    return "word \(number) of 12"
  }

}
