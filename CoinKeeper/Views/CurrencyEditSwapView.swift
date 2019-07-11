//
//  CurrencyEditSwapView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/11/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class CurrencyEditSwapView: UIView {

  @IBOutlet var primaryAmountTextField: LimitEditTextField!
  @IBOutlet var secondaryAmountLabel: UILabel!
  @IBOutlet var swapButton: UIButton!

  private func setupUI() {
    secondaryAmountLabel.textColor = .darkGrayText
    secondaryAmountLabel.font = .regular(17)
  }
}
