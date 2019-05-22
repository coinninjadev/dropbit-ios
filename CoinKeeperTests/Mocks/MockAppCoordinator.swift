//
//  MockAppCoordinator.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit

class MockAppCoordinator: AppCoordinator {
  var wasAskedToEnterActiveState = false
  var wasAskedToResignActiveState = false

  override func appEnteredActiveState() {
    wasAskedToEnterActiveState = true
  }

  override func appWillResignActiveState() {
    wasAskedToResignActiveState = true
  }
}
