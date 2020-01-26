//
//  UITestPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

/**
 Subclasses of UITestPage should correspond 1-to-1 with view controllers in the target app.
 The subclass page should define functions that can be reused by different test cases.
 This approach was taken from: https://github.com/danielCarlosCE/XCUITestExample
 */
class UITestPage {

  let app = XCUIApplication()
  let pageElement: AccessiblePageElement

  init(page: AccessiblePageElement,
       assertionWait: AssertionWait = .default,
       ifExists: AssertionWaitCompletion = nil) {
    self.pageElement = page
    rootElement.assertExistence(afterWait: assertionWait, elementDesc: String(describing: self), ifExists: ifExists)
  }

  /**
   For some testing flows, a page may or may not be present. This optional initializer
   allows the chained steps for that page to be skipped without failing the test.
   */
  init?(optionalPage: AccessiblePageElement, assertionWait: AssertionWait = .default) {
    self.pageElement = optionalPage

    switch assertionWait {
    case .none:
      guard rootElement.exists else { return nil }
    default:
      let pageExists = rootElement.waitForExistence(timeout: assertionWait.duration)
      guard pageExists else { return nil }
    }
  }

  var rootElement: XCUIElement {
    return app.otherElements[pageElement.identifier]
  }

  @discardableResult
  func tapBack() -> Self {
    app.navigationBars.buttons.element(boundBy: 0).tap()
    return self
  }

}
