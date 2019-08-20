//
//  UITestCase.swift
//  DropBitUITests
//
//  Created by Ben Winters on 10/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class UITestCase: XCTestCase {
  let app = XCUIApplication()

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app.launchArguments.append("ui-test")
    // Subclasses should call app.launch() at the end of their override of this function
  }

  override func tearDown() {
    super.tearDown()
    app.terminate()
  }

  /// This value should match the UITestArgument enum case in the target app.
  func appendTestArgument(_ argument: UITestArgument) {
    app.launchArguments.append(argument.fullArgument)
  }

  /**
   - param isRequired: Defaults to true. Set to false if the element is sometimes not present and can be ignored.
   - param successHandler: Use this closure to perfom actions and make assertions that should only be run if the `element` exists.
   */
  // TODO: Delete this function once all UI tests use pages
  func waitForElementToAppear(_ element: XCUIElement,
                              timeout: TimeInterval = 3,
                              isRequired: Bool = true,
                              file: String = #file,
                              line: Int = #line,
                              ifExists successHandler: CKCompletion? = nil) {

    let exists = element.waitForExistence(timeout: timeout)
    if exists {
      successHandler?()
    } else if isRequired {
      let message = "Failed to find \(element) after \(timeout) seconds."
      self.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
    }
  }

  func addSystemAlertMonitor(buttonTitles: [String] = ["Allow", "Always Allow"]) {

    addUIInterruptionMonitor(withDescription: "alert monitor") { (alert) -> Bool in
      for buttonTitle in buttonTitles {
        let button = alert.buttons[buttonTitle]
        if button.exists {
          button.tap()
          return true
        }
      }

      XCTFail("Unexpected System Alert")
      return false
    }
  }

}
