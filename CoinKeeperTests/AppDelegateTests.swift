//
// Created by BJ Miller on 2/19/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class AppDelegateTests: XCTestCase {
  var sut: AppDelegate!
  var mockCoordinator: MockAppCoordinator!

  override func setUp() {
    super.setUp()
    self.sut = UIApplication.shared.delegate as? AppDelegate
    self.mockCoordinator = MockAppCoordinator()
    self.sut.coordinator = mockCoordinator
  }

  override func tearDown() {
    self.sut = nil
    self.mockCoordinator = nil
    super.tearDown()
  }

  // MARK: entering foreground
  func testEnteringForegroundTellsCoordinatorAppBecameActive() {
    self.sut.applicationWillEnterForeground(UIApplication.shared)
    XCTAssertTrue(mockCoordinator.wasAskedToEnterActiveState)
  }

  // MARK: resigning active
  func testResigningActiveTellsCoordinatorAppResigned() {
    self.sut.applicationWillResignActive(UIApplication.shared)
    XCTAssertTrue(mockCoordinator.wasAskedToResignActiveState)
  }
}
