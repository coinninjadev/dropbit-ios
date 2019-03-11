//
//  BalancePrimaryAmountLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BalancePrimaryAmountLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.balancePrimaryAmount.font
    textColor = Theme.Color.darkBlueText.color
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }
}
