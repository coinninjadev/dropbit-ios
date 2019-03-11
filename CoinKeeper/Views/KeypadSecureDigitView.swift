//
//  KeypadSecureDigitView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

// Note: This class is deprecated in favor of setting PinDisplayView.isSecure = true
// I'm leaving it here for now because so many unit tests reference it.
// Re-writing the unit tests is not something anyone has time for right now. (wjf, 2018-04)

import UIKit

@IBDesignable
class KeypadSecureDigitView: KeypadDigitView {

  override var isSecure: Bool {
    get { return true }
    set { guard newValue else { fatalError("Unsupported behavior") } }
  }

}
