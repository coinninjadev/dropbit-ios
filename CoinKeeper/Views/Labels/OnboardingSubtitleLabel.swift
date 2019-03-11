//
//  OnboardingSubtitleLabel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class OnboardingSubtitleLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.onboardingSubtitle.font
    textColor = Theme.Color.grayText.color
  }
}
