//
//  XCUIApplication+UITestArgument.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

extension XCUIApplication {

  func appendTestArguments(_ arguments: [UITestArgument]) {
    arguments.forEach { self.appendTestArgument($0) }
  }

  /// This value should match the UITestArgument enum case in the target app.
  func appendTestArgument(_ argument: UITestArgument) {
    self.launchArguments.append(argument.fullArgument)
  }

}
