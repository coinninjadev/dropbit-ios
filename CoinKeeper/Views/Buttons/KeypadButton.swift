//
//  KeypadButton.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class KeypadButton: UIButton {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    // Don't set titleColor so we inherit the superview's tintColor (wjf, 2018-04)
    titleLabel?.font = Theme.Font.keypadButton.font
    backgroundColor = .clear
    adjustsImageWhenHighlighted = true
  }
}
