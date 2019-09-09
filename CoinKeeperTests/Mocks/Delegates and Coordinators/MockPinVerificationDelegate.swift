//
// Created by BJ Miller on 2/16/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import UIKit

class MockPinVerificationDelegate: PinVerificationDelegate {
  var pinWasVerified = false
  var pinFailCountExceeded = false
  var digits: String = ""

  func pinWasVerified(digits: String, for flow: SetupFlow?) {
    pinWasVerified = true
    self.digits = digits
  }

  func viewControllerPinFailureCountExceeded(_ viewController: UIViewController) {
    pinFailCountExceeded = true
  }
}
