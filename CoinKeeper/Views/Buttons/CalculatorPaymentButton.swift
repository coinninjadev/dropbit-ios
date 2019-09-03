//
//  CalculatorPaymentButton.swift
//  DropBit
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

 class CalculatorPaymentButton: UIButton {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    setTitleColor(.lightGrayText, for: .normal)
    titleLabel?.font = .primaryButtonTitle
    backgroundColor = .clear
    adjustsImageWhenHighlighted = true
  }
}
