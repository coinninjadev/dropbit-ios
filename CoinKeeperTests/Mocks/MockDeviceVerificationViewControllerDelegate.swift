//
//  MockDeviceVerificationViewControllerDelegate.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit

class MockDeviceVerificationViewControllerDelegate: DeviceVerificationViewControllerDelegate {

  var didRequestResend = false
  func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController, temporaryUserId: String) {
    didRequestResend = true
  }

  func viewControllerShouldShowSkipButton() -> Bool {
    return true
  }

  var expectedCode = "123456"

  var phoneNumberWasEntered = false
  func viewController(_ viewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber) {
    phoneNumberWasEntered = true
  }

  var codeWasEntered = false
  func viewController(_ codeEntryViewController: DeviceVerificationViewController,
                      didEnterCode code: String,
                      forUserId userId: String,
                      completion: @escaping (Bool) -> Void) {
    codeWasEntered = true
    completion(code == expectedCode)
  }

  var verificationSkipped = false
  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController) {
    verificationSkipped = true
  }

  var twitterWasSelected = false
  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) {
    twitterWasSelected = true
  }

}
