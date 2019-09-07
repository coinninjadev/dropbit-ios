//
//  MockPinCreationEntryDelegate.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit

class MockPinCreationEntryDelegate: PinCreationEntryDelegate {
  var pinWasFullyEntered = false
  var digits: String = ""

  func viewControllerFullyEnteredPin(_ viewController: PinCreationViewController, digits: String) {
    pinWasFullyEntered = true
    self.digits = digits
  }
}
