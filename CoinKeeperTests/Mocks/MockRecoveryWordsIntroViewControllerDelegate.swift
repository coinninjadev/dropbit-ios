//
//  MockRecoveryWordsIntroViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit

class MockRecoveryWordsIntroViewControllerDelegate: RecoveryWordsIntroViewControllerDelegate {

  var wasAskedToVerifyWords = false
  func verifyIfWordsAreBackedUp() -> Bool {
    wasAskedToVerifyWords = true
    return wasAskedToVerifyWords
  }

  var wasAskedToBackupRecoveryWords = false
  func viewController(_ viewController: UIViewController, didChooseToBackupWords words: [String]) {
    wasAskedToBackupRecoveryWords = true
  }

  var wasAskedToSkipRecoveryWords = false
  func viewController(_ viewController: UIViewController, didSkipWords words: [String]) {
    wasAskedToSkipRecoveryWords = true
  }

}
