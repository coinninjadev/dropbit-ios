//
//  TransactionDetailBottomButton.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailBottomButton: UIButton {
  override func awakeFromNib() {
    super.awakeFromNib()
    layer.cornerRadius = 4
    layer.masksToBounds = true
    backgroundColor = Theme.Color.darkBlueButton.color
    setTitleColor(Theme.Color.extraLightGrayBackground.color, for: .normal)
    titleLabel?.font = Theme.Font.primaryButtonTitle.font
  }
}
