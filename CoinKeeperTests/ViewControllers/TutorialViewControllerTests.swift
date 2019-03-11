//
//  TutorialViewControllerTests.swift
//  DropBit
//
//  Created by Mitch on 12/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class TutorialViewControllerTests: XCTestCase {
  var sut: TutorialViewController!

  override func setUp() {
    self.sut = TutorialViewController.makeFromStoryboard()
    _ = sut.view
  }

  func testTutorialScreenViewControllerDelegateAssignment() {
    let tutorialScreenViewController = sut.createViewController(at: 2)
    XCTAssertNotNil(tutorialScreenViewController?.delegate, "tutorialScreenViewController should have an assigned delegate")
  }
}
