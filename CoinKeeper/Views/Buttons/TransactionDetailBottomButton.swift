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
    applyCornerRadius(4)
    backgroundColor = .darkBlueButton
    setTitleColor(.extraLightGrayBackground, for: .normal)
    titleLabel?.font = .primaryButtonTitle
  }
}
