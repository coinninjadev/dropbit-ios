//
//  Springboard.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import XCTest

class Springboard {
  static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

  /**
   Terminate and delete the app via springboard
   */
  class func deleteMyApp() {
    XCUIApplication().terminate()

    // Force delete the app from the springboard
    let icon = springboard.icons["DropBitBeta"]
    if icon.exists {
      let iconFrame = icon.frame
      let springboardFrame = springboard.frame
      icon.press(forDuration: 1.3)

      // Tap the little "X" button at approximately where it is. The X is not exposed directly
      let vector = CGVector(dx: (iconFrame.minX + 3) * UIScreen.main.scale / springboardFrame.maxX,
                            dy: (iconFrame.minY + 3) * UIScreen.main.scale / springboardFrame.maxY)
      springboard.coordinate(withNormalizedOffset: vector).tap()

      let deleteConfirmationButton = springboard.alerts.buttons["Delete"]
      _ = deleteConfirmationButton.waitForExistence(timeout: 3)
      deleteConfirmationButton.tap()

      // Press home once make the icons stop wiggling
      XCUIDevice.shared.press(.home)
      // Press home again to go to the first page of the springboard
      XCUIDevice.shared.press(.home)
      // Wait some time for the animation end
      Thread.sleep(forTimeInterval: 0.5)
    }
  }
}
