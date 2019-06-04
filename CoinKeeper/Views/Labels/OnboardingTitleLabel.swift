//
//  OnboardingTitleLabel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class OnboardingTitleLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.medium(19)
    textColor = .grayText
  }
}
