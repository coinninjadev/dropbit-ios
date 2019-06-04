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
    font = CKFont.medium(19)
    textColor = .darkBlueText
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }
}
