//
//  MemoEntryPage.swift
//  DropBitUITests
//
//  Created by BJ Miller on 12/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class MemoEntryPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .memoEntry(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func enterText(_ text: String, count: Int = 1) -> Self {
    let textView = app.textViews.firstMatch
    textView.assertExistence(afterWait: .none, elementDesc: "memoEntryTextView")
    count.times {
      textView.typeText(text)
    }
    return self
  }

  @discardableResult
  func assertCharacterLimit(of limit: Int) -> Self {
    let textView = app.textViews.firstMatch
    textView.assertExistence(afterWait: .none, elementDesc: "memoEntryTextView")
    let text = (textView.value as? String) ?? ""
    XCTAssertEqual(text.count, limit)
    return self
  }

  @discardableResult
  func clearText() -> Self {
    let textView = app.textViews.firstMatch
    textView.press(forDuration: 1.5)
    app.menuItems["Select All"].tap()
    app/*@START_MENU_TOKEN@*/.menuItems["Cut"]/*[[".menus.menuItems[\"Cut\"]",".menuItems[\"Cut\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    return self
  }

  @discardableResult
  func tapToDismiss() -> Self {
    app/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".keyboards.buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    return self
  }
}
