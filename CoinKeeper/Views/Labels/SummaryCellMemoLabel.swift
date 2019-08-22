//
//  SummaryCellMemoLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellMemoLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .semiBold(16)
    textColor = .darkBlueText
    isHidden = true
    numberOfLines = 1
    textAlignment = .left
  }
}
