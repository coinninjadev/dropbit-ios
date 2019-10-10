//
//  OnboardingSubtitleLabel.swift
//  DropBit
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class OnboardingSubtitleLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .regular(15)
    textColor = .darkGrayText
  }
}
