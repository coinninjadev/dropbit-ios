//
//  XCUIApplication+WaitAndAssert.swift
//  DropBitUITests
//
//  Created by Ben Winters on 10/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

typealias AssertionWaitCompletion = (() -> Void)?

extension XCUIElement {

  func assertExistence(afterWait wait: AssertionWait,
                       elementDesc: String,
                       isRequired: Bool = true,
                       ifExists completion: AssertionWaitCompletion = nil) {
    switch wait {
    case .default:
      self.assertExistence(afterWait: .custom(AssertionWait.default.duration),
                           elementDesc: elementDesc,
                           ifExists: completion)

    case .none:
      if !self.exists && isRequired {
        XCTAssert(self.exists, "\(elementDesc) did not immediately exist")
      } else {
        completion?()
      }

    case .custom(let timeout):
      print("Waiting for existence of \(elementDesc)")
      let exists = self.waitForExistence(timeout: timeout)
      if !exists && isRequired {
        XCTAssert(exists, "\(elementDesc) does not exist after \(timeout)s timeout")
      } else {
        completion?()
      }
    }
  }

}

enum AssertionWait {
  case none
  case `default`
  case custom(TimeInterval)

  var duration: TimeInterval {
    switch self {
    case .none:               return 0
    case .default:            return 5
    case .custom(let value):  return value
    }
  }

}

/**
 Getting a reference to an XCUIElement through a defined AccessiblePageElement applies assertions automatically and includes
 default values for the wait behavior. View controllers are returned after the default wait of 5 seconds,
 subviews do not have a wait and are asserted immediately by default.
 */
extension XCUIApplication {

  func viewController(withId pageElement: AccessiblePageElement, assertionWait: AssertionWait = .default) -> XCUIElement {
    let viewController = otherElements[pageElement.identifier]
    viewController.assertExistence(afterWait: assertionWait, elementDesc: pageElement.identifier)
    return viewController
  }

  func view(withId pageElement: AccessiblePageElement, assertionWait: AssertionWait = .default) -> XCUIElement {
    let viewController = otherElements[pageElement.identifier]
    viewController.assertExistence(afterWait: assertionWait, elementDesc: pageElement.identifier)
    return viewController
  }

  func buttons(_ pageElement: AccessiblePageElement, assertionWait: AssertionWait = .none) -> XCUIElement {
    let button = self.buttons[pageElement.identifier]
    button.assertExistence(afterWait: assertionWait, elementDesc: pageElement.identifier)
    return button
  }

  func textFields(_ pageElement: AccessiblePageElement, assertionWait: AssertionWait = .none) -> XCUIElement {
    let textField = self.textFields[pageElement.identifier]
    textField.assertExistence(afterWait: assertionWait, elementDesc: textField.identifier)
    return textField
  }

  func staticTexts(_ pageElement: AccessiblePageElement, assertionWait: AssertionWait = .none) -> XCUIElement {
    let staticText = self.staticTexts[pageElement.identifier]
    staticText.assertExistence(afterWait: assertionWait, elementDesc: pageElement.identifier)
    return staticText
  }

}
