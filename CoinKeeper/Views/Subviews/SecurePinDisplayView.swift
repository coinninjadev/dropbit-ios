//
//  SecurePinDisplayView.swift
//  DropBit
//
//  Created by BJ Miller on 2/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

// Note: This class is deprecated in favor of setting PinDisplayView.isSecure = true
// I'm leaving it here for now because so many unit tests reference it.
// Re-writing the unit tests is not something anyone has time for right now. (wjf, 2018-04)

import UIKit

class SecurePinDisplayView: PinDisplayView {

  override var isSecure: Bool {
    get { return true }
    set { guard newValue else { fatalError("Unsupported behavior") } }
  }

  // Shims for unit tests until we re-write them for the superclass
  var secureDigitView1: KeypadDigitView! { return super.digitView1 }
  var secureDigitView2: KeypadDigitView! { return super.digitView2 }
  var secureDigitView3: KeypadDigitView! { return super.digitView3 }
  var secureDigitView4: KeypadDigitView! { return super.digitView4 }
  var secureDigitView5: KeypadDigitView! { return super.digitView5 }
  var secureDigitView6: KeypadDigitView! { return super.digitView6 }

  // Informs super's invocation of xibSetup() which xib file to load
  override var xibName: String { return "PinDisplayView" }

  override func awakeFromNib() {
    super.awakeFromNib()
    super.isSecure = true // sets all subviews to secure mode
  }

  // MARK: PinDisplayable

  override func setDigits(_ digits: String) {
    showNumberOfDigits(digits.count)
  }

  // MARK: Private

  // Note: I left this Internal instead of `private` so I wouldn't have to touch all the tests that call it
  // (it's an easy fix, though: replace showNumberOfDigits(4) call sites with setDigits("1234") (wjf, 2018-04)
  func showNumberOfDigits(_ count: Int) {
    guard (0...allViews.count) ~= count else { return }
    allViews.enumerated().forEach { (index, view) in view.digit = (index < count) ? "•" : "" }
  }
}
