//
//  CalculatorSecondaryAmountLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CalculatorSecondaryAmountLabel: UILabel {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    textColor = Theme.Color.grayText.color
    font = Theme.Font.calculatorSecondaryAmount.font
    backgroundColor = .clear
  }
}
