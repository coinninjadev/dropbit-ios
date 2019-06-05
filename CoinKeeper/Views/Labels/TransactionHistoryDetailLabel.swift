//
//  TransactionHistoryDetailLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryDetailLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .regular(12)
    textColor = .grayText
    isHidden = false
    numberOfLines = 1
    textAlignment = .left
  }
}
